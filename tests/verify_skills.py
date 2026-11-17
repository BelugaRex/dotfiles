#!/usr/bin/env python3
"""Offline skill-package checks; fixtures never touch the real HOME or agi-gallery."""
from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import unittest
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
ENTRIES = {
    "agi-gallery", "always-ask-next", "answer-framework", "cavecrew", "caveman",
    "double-check", "i-have-adhd", "improve-codebase-architecture",
    "karpathy-guidelines", "planning-with-files", "pua", "refactoring-fowler",
}
MANAGED = ENTRIES - {"agi-gallery"}
LICENSES = {
    "caveman": "LICENSE-MIT", "i-have-adhd": "LICENSE",
    "improve-codebase-architecture": "LICENSE", "planning-with-files": "LICENSE",
}


def managed_files():
    # Do not recurse through the excluded directory, even to discover files.
    for name in sorted(MANAGED):
        yield from sorted(p for p in (SKILLS / name).rglob("*") if p.is_file())


def clean_env(home):
    env = {"PATH": os.defpath, "HOME": str(home), "LANG": "C.UTF-8",
           "PYTHONDONTWRITEBYTECODE": "1", "PYTHONNOUSERSITE": "1"}
    env["XDG_CONFIG_HOME"] = str(home / ".config")
    return env


class SkillPackageTests(unittest.TestCase):
    def command(self, args, *, cwd, env=None, expected=0):
        result = subprocess.run([str(arg) for arg in args], cwd=cwd, env=env,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, expected,
                         f"{Path(args[0]).name}: {result.stdout}\n{result.stderr}")
        return result.stdout

    def test_inventory_and_frontmatter_contract(self):
        self.assertEqual({p.name for p in SKILLS.iterdir() if p.is_dir()}, ENTRIES)
        for name in sorted(MANAGED):
            with self.subTest(skill=name):
                text = (SKILLS / name / "SKILL.md").read_text(encoding="utf-8")
                match = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
                self.assertIsNotNone(match)
                header = match.group(1)
                self.assertRegex(header, rf"(?m)^name: {re.escape(name)}\s*$")
                self.assertRegex(header, r"(?m)^description:\s*\S")
                self.assertNotIn("\t", header)
        for name in ("i-have-adhd", "improve-codebase-architecture"):
            self.assertIn("disable-model-invocation: true",
                          (SKILLS / name / "SKILL.md").read_text())
        self.assertIn('adapter-revision: "copilot.1"',
                      (SKILLS / "planning-with-files/SKILL.md").read_text())

    def test_active_relative_links_and_licenses(self):
        for name in sorted(MANAGED):
            entry = SKILLS / name / "SKILL.md"
            for target in re.findall(r"\]\(([^\s)]+)\)", entry.read_text()):
                if re.match(r"[a-zA-Z][\w+.-]*:", target) or target.startswith("#"):
                    continue
                path = unquote(target.split("#", 1)[0])
                resolved = (entry.parent / path).resolve()
                with self.subTest(skill=name, target=target):
                    self.assertTrue(resolved.is_relative_to(entry.parent.resolve()))
                    self.assertTrue(resolved.exists(), f"Missing skill reference: {name}/{path}")
        for name, filename in LICENSES.items():
            notice = (SKILLS / name / filename).read_text()
            self.assertIn("Permission is hereby granted", notice)
            self.assertIn("Copyright", notice)
        self.assertIn("no LICENSE file", (SKILLS / "pua/LOCAL-PATCH.md").read_text())

    def test_syntax_and_public_path_hygiene(self):
        paths = list(managed_files()) + [ROOT / "README.md", ROOT / "install.sh",
                                        ROOT / "bashrc.d/custom.sh",
                                        ROOT / "fonts/install-font.sh", Path(__file__)]
        private = re.compile(r"/(?:home|Users)/[^/\s`]+/|/mnt/[a-z]/Users/")
        secret = re.compile(r"(?:github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|"
                            r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)")
        for path in paths:
            with self.subTest(path=str(path.relative_to(ROOT))):
                data = path.read_bytes()
                text = data.decode("utf-8")
                self.assertIsNone(private.search(text), "Private absolute path in public file")
                self.assertIsNone(secret.search(text), "Credential-shaped content in public file")
                if path.suffix == ".sh":
                    self.command(["bash", "-n", path], cwd=ROOT)
                elif path.suffix == ".py":
                    compile(data, str(path), "exec")
                elif path.suffix == ".toml":
                    tomllib.loads(text)
                self.assertNotIn("__pycache__", path.parts)

    def test_documented_inventory_and_migration(self):
        readme = (ROOT / "README.md").read_text()
        self.assertIn("**12 个入口**", readme)
        self.assertIn("**39 个旧入口**", readme)
        for name in ENTRIES:
            self.assertIn(f"`{name}`", readme)
        self.assertIn("脱敏要求（分享 / AI 会话前必做）", readme)
        self.assertIn("不会自动删除", readme)
        self.assertIn("不注册生命周期 hooks", readme)

    def test_install_isolated_idempotent_and_preserves_unmanaged(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-check-") as directory:
            base = Path(directory)
            repo, home, outside = base / "repo", base / "home", base / "external"
            repo.mkdir()
            home.mkdir()
            outside.mkdir()
            (outside / "keep.txt").write_text("third-party original\n")
            shutil.copy2(ROOT / "install.sh", repo / "install.sh")
            shutil.copytree(ROOT / "config", repo / "config")
            shutil.copytree(ROOT / "bashrc.d", repo / "bashrc.d")
            for name in ENTRIES:
                source = repo / "skills" / name
                source.mkdir(parents=True)
                (source / "SKILL.md").write_text(f"synthetic package: {name}\n")
            destination = home / ".agents/skills"
            destination.mkdir(parents=True)
            (destination / "unrelated-dir").mkdir()
            (destination / "unrelated-dir/keep").write_text("local\n")
            (destination / "unrelated-link").symlink_to(outside, target_is_directory=True)
            (destination / "unrelated-dangling").symlink_to(base / "absent")
            (destination / "pua-en").mkdir()
            (destination / "pua-en/keep").write_text("retired local modifications\n")
            (destination / "pua").symlink_to(outside, target_is_directory=True)
            (destination / "caveman").mkdir()
            (destination / "caveman/stale").write_text("old\n")
            (home / ".bashrc").write_text("# user config\n")
            (home / ".config").mkdir()
            (home / ".config/starship.toml").write_text("# user starship\n")
            stubs = base / "bin"
            stubs.mkdir()
            log = base / "network-attempts"
            for command in ("curl", "wget", "brew", "winget"):
                stub = stubs / command
                stub.write_text(f"#!/bin/sh\nprintf 'blocked\\n' >> '{log}'\nexit 97\n")
                stub.chmod(0o755)
            zsh = stubs / "zsh"
            zsh.write_text("#!/bin/sh\nexit 0\n")
            zsh.chmod(0o755)
            env = clean_env(home)
            env["PATH"] = str(stubs) + os.pathsep + os.defpath
            for _ in range(2):
                self.command(["bash", repo / "install.sh", "--without-starship",
                              "--without-font"], cwd=repo, env=env)
                for name in ENTRIES:
                    self.assertFalse((destination / name).is_symlink())
                    self.assertEqual((destination / name / "SKILL.md").read_text(),
                                     f"synthetic package: {name}\n")
                self.assertFalse((destination / "caveman/stale").exists())
                self.assertEqual((outside / "keep.txt").read_text(), "third-party original\n")
                self.assertEqual((destination / "unrelated-dir/keep").read_text(), "local\n")
                self.assertTrue((destination / "unrelated-link").is_symlink())
                self.assertTrue((destination / "unrelated-dangling").is_symlink())
                self.assertEqual((destination / "pua-en/keep").read_text(),
                                 "retired local modifications\n")
                for filename in (".bashrc", ".zshrc"):
                    self.assertEqual((home / filename).read_text().count(
                        "# >>> dotfiles-loader >>>"), 1)
            self.assertEqual(len(list(home.glob(".bashrc.bak.*"))), 1)
            self.assertEqual(next(home.glob(".bashrc.bak.*")).read_text(), "# user config\n")
            self.assertEqual(next((home / ".config").glob("starship.toml.bak.*")).read_text(),
                             "# user starship\n")
            self.assertFalse(log.exists(), "Installer attempted a download")

    def test_installer_help_and_skill_backup(self):
        with tempfile.TemporaryDirectory(prefix="dotfiles-ux-") as directory:
            base = Path(directory)
            repo, home = base / "repo", base / "home"
            repo.mkdir()
            home.mkdir()
            shutil.copy2(ROOT / "install.sh", repo / "install.sh")
            shutil.copytree(ROOT / "config", repo / "config")
            shutil.copytree(ROOT / "bashrc.d", repo / "bashrc.d")
            for name in ENTRIES:
                source = repo / "skills" / name
                source.mkdir(parents=True)
                (source / "SKILL.md").write_text("packaged version\n")
            stubs = base / "bin"
            stubs.mkdir()
            log = base / "network-attempts"
            for command in ("curl", "wget", "brew", "winget"):
                stub = stubs / command
                stub.write_text(f"#!/bin/sh\nprintf 'blocked\\n' >> '{log}'\nexit 97\n")
                stub.chmod(0o755)
            env = clean_env(home)
            env["PATH"] = str(stubs) + os.pathsep + os.defpath
            # --help 必须零副作用: 打印帮助, 且不创建任何 HOME 内容
            help_text = self.command(["bash", repo / "install.sh", "--help"], cwd=repo, env=env)
            self.assertIn("--with-font", help_text)
            self.assertFalse((home / ".bashrc").exists())
            self.assertFalse((home / ".agents").exists())
            # 有本地差异的技能: 覆盖前必须留一份时间戳备份
            current = home / ".agents/skills/pua"
            current.mkdir(parents=True)
            (current / "SKILL.md").write_text("local edit\n")
            self.command(["bash", repo / "install.sh", "--without-starship",
                          "--without-font"], cwd=repo, env=env)
            self.assertEqual((current / "SKILL.md").read_text(), "packaged version\n")
            backups = sorted((home / ".agents/skills-backup").glob("*/pua/SKILL.md"))
            self.assertEqual([p.read_text() for p in backups], ["local edit\n"])
            # 内容一致时重跑不再产生新备份(幂等)
            self.command(["bash", repo / "install.sh", "--without-starship",
                          "--without-font"], cwd=repo, env=env)
            self.assertEqual(len(list((home / ".agents/skills-backup").iterdir())), 1)
            self.assertFalse(log.exists(), "Installer attempted a download")

    def test_caveman_synthetic_eligibility_and_candidates(self):
        scripts = SKILLS / "caveman/scripts"
        spec = importlib.util.spec_from_file_location("skill_detect", scripts / "detect.py")
        detector = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(detector)
        with tempfile.TemporaryDirectory(prefix="prose-check-") as directory:
            base = Path(directory)
            # Missing sensitive fixtures prove the detector can refuse before any content read.
            for name in (".env", ".env.local", "credentials.txt", "token-notes.md"):
                self.assertEqual(detector.detect_file_type(base / name), "config")
            self.assertEqual(detector.detect_file_type(base / "notes.md"), "natural_language")
            self.assertEqual(detector.detect_file_type(base / "CMakeLists.txt"), "code")
            self.assertEqual(detector.detect_file_type(base / "paper.tex"), "code")
            generated = base / "generated.md"
            generated.write_text("Generated by a fixture\n")
            self.assertFalse(detector.should_compress(generated))
            original, candidate = base / "before.md", base / "after.md"
            original.write_text("# Notes\n\nPlease preserve the exact `api/v1` endpoint in this long sentence.\n")
            candidate.write_text("# Notes\n\nPreserve `api/v1` endpoint.\n")
            self.command([sys.executable, "-B", scripts / "check_candidate.py",
                          original, candidate], cwd=base, env=clean_env(base))
            candidate.write_text("# Notes\n\nPreserve `api/v2` endpoint.\n")
            self.command([sys.executable, "-B", scripts / "check_candidate.py",
                          original, candidate], cwd=base, env=clean_env(base), expected=1)

    def test_planning_isolated_initialization_and_rejection(self):
        scripts = SKILLS / "planning-with-files/scripts"
        with tempfile.TemporaryDirectory(prefix="plan-check-") as directory:
            base = Path(directory)
            env = clean_env(base)
            self.command(["bash", scripts / "init-session.sh", "--help"], cwd=base, env=env)
            self.assertEqual(list(base.iterdir()), [])
            self.command(["bash", scripts / "init-session.sh", "--unknown"],
                         cwd=base, env=env, expected=1)
            self.assertEqual(list(base.iterdir()), [])
            self.command(["bash", scripts / "init-session.sh", "Skill publication"],
                         cwd=base, env=env)
            plans = [p for p in (base / ".planning").iterdir() if p.is_dir()]
            self.assertEqual(len(plans), 1)
            plan = plans[0]
            for name in ("task_plan.md", "findings.md", "progress.md"):
                self.assertTrue((plan / name).is_file())
            self.assertFalse((plan / ".mode").exists())
            self.command(["bash", scripts / "check-complete.sh", "--validate",
                          plan / "task_plan.md"], cwd=base, env=env)
            invalid = dict(env, PLAN_ID="missing-plan", PWF_PLAN_ROOT=str(base))
            output = self.command(["bash", scripts / "check-complete.sh", "--validate"],
                                  cwd=base, env=invalid, expected=1)
            self.assertIn("no other plan was substituted", output)
            malformed = base / "malformed.md"
            malformed.write_text("### Phase 1: Invalid\nNo status here.\n")
            self.command(["bash", scripts / "check-complete.sh", "--validate", malformed],
                         cwd=base, env=env, expected=1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
