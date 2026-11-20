"""Unit tests for cross-platform local-first si-agent."""

import tempfile
import unittest
from pathlib import Path

from si_agent import run_local_agent


class TestLocalAgent(unittest.TestCase):
    def test_free_local_tier0_run_writes_log(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            res = run_local_agent(
                goal="Audit local scripts",
                tokens=512,
                ranks=1,
                allow_cloud=False,
                log_dir=tmp,
            )
            self.assertEqual(res["routing"]["tier"], 0)
            self.assertEqual(res["cost_usd_estimate"], 0.0)
            self.assertEqual(res["status"], "completed_local_dry_run")
            self.assertTrue(Path(res["log_file"]).exists())

    def test_hitl_gate_pauses_without_approval(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            res = run_local_agent(
                goal="Scale across 4 ranks",
                tokens=4096,
                ranks=4,
                allow_cloud=False,
                approve_hitl=False,
                log_dir=tmp,
            )
            self.assertEqual(res["routing"]["tier"], 2)
            self.assertEqual(res["status"], "awaiting_hitl_approval")


if __name__ == "__main__":
    unittest.main()
