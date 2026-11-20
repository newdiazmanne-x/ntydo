"""Tests for auto-aware computability routing, spec loading, and CLI behavior."""

import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from si_router import DEFAULT_THRESHOLDS, load_routing_config, route_workload
from si_router.cli import main as cli_main


class TestSpecLoadingAndFallbacks(unittest.TestCase):
    def test_missing_spec_falls_back_to_defaults(self) -> None:
        cfg = load_routing_config("/tmp/nonexistent-si-spec-12345.json")
        self.assertEqual(cfg, DEFAULT_THRESHOLDS)

    def test_malformed_json_falls_back_to_defaults(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bad_file = Path(tmp) / "bad.json"
            bad_file.write_text("{not-valid-json", encoding="utf-8")
            self.assertEqual(load_routing_config(bad_file), DEFAULT_THRESHOLDS)

    def test_custom_thresholds_from_spec_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            spec_file = Path(tmp) / "spec.json"
            spec_file.write_text(
                json.dumps(
                    {
                        "routing_thresholds": {
                            "tier1_tokens": 1000,
                            "tier3_tokens": 5000,
                        }
                    }
                ),
                encoding="utf-8",
            )
            tier1 = route_workload(1500, 1, False, spec_path=spec_file)
            self.assertEqual(tier1["tier"], 1)

            tier3 = route_workload(6000, 1, True, spec_path=spec_file)
            self.assertEqual(tier3["tier"], 3)
            self.assertTrue(tier3["hitl_required"])


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
        blocked = route_workload(task_tokens=20000, distributed_ranks=1, allow_cloud=False)
        self.assertEqual(blocked["tier"], 1)

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
