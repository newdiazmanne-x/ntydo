"""Tests for auto-aware computability routing and CLI behavior."""

import io
import json
import unittest
from contextlib import redirect_stdout

from si_router import route_workload
from si_router.cli import main as cli_main


class TestRouteWorkload(unittest.TestCase):
    def test_tier_0_edge_default(self) -> None:
        decision = route_workload(task_tokens=2048, distributed_ranks=1, allow_cloud=False)
        self.assertEqual(decision["tier"], 0)
        self.assertEqual(decision["mode"], "edge-termux-deterministic")
        self.assertFalse(decision["hitl_required"])

    def test_tier_1_sparse_moe(self) -> None:
        decision = route_workload(task_tokens=4096, distributed_ranks=1, allow_cloud=False)
        self.assertEqual(decision["tier"], 1)
        self.assertEqual(decision["mode"], "sparse-moe-local-or-lan")
        self.assertFalse(decision["hitl_required"])

    def test_tier_2_openmpi_llvm_requires_hitl(self) -> None:
        decision = route_workload(task_tokens=8192, distributed_ranks=4, allow_cloud=False)
        self.assertEqual(decision["tier"], 2)
        self.assertEqual(decision["mode"], "openmpi-llvm-fused")
        self.assertTrue(decision["hitl_required"])

    def test_tier_3_cloud_requires_flag_and_tokens(self) -> None:
        # Without --allow-cloud, 20000 tokens with 1 rank should not jump to Tier 3
        blocked = route_workload(task_tokens=20000, distributed_ranks=1, allow_cloud=False)
        self.assertEqual(blocked["tier"], 1)

        # With --allow-cloud and >= 16384 tokens, Tier 3 is selected with HITL required
        allowed = route_workload(task_tokens=20000, distributed_ranks=1, allow_cloud=True)
        self.assertEqual(allowed["tier"], 3)
        self.assertEqual(allowed["mode"], "cloud-google-ai-scale")
        self.assertTrue(allowed["hitl_required"])


class TestCliEntrypoint(unittest.TestCase):
    def test_cli_outputs_valid_json(self) -> None:
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = cli_main(["--tokens", "8192", "--ranks", "4"])
        self.assertEqual(rc, 0)
        payload = json.loads(buf.getvalue())
        self.assertEqual(payload["tier"], 2)
        self.assertTrue(payload["hitl_required"])


if __name__ == "__main__":
    unittest.main()
