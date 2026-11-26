import json
import os
import pathlib
import re
import subprocess
import shlex
import time
import unittest

import yaml


ROOT = pathlib.Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "kubernetes/victoriametrics/image-outdated.yml"


def documents():
    return [item for item in yaml.safe_load_all(MANIFEST.read_text()) if item]


def script():
    return documents()[0]["data"]["outdated.sh"]


class ImageReportingTests(unittest.TestCase):
    def test_chart_manager_matches_every_chart_application(self):
        config = json.loads((ROOT / "renovate.json").read_text())
        patterns = [re.compile(pattern[1:-1]) for pattern in config["argocd"]["managerFilePatterns"]]
        charts = []
        for path in (ROOT / "kubernetes/argocd").rglob("*.yml"):
            for item in yaml.safe_load_all(path.read_text()):
                if not isinstance(item, dict) or item.get("kind") != "Application":
                    continue
                spec = item["spec"]
                sources = spec.get("sources", [spec.get("source", {})])
                if any(source.get("chart") for source in sources):
                    charts.append(path.relative_to(ROOT).as_posix())
        self.assertGreater(len(charts), 10)
        self.assertEqual([], [path for path in charts if not any(pattern.search(path) for pattern in patterns)])

    def report(self, rows, overrides=""):
        prelude, loop = script().split(': >"$WORK/out"', 1)
        payload = prelude + "\nseries() { printf '%s\\n' " + shlex.quote(rows) + "; }\n" + overrides + '\n: >"$WORK/out"' + loop
        return subprocess.run(["bash"], input=payload, capture_output=True, text=True)

    def test_failed_timestamp_lookup_is_explicitly_unknown(self):
        result = self.report("quay.io/example/app\tv1.0.0\tv2.0.0", "tag_created() { return 1; }")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn('image_version_lookup_success{image="quay.io/example/app",current_version="v1.0.0",latest_version="v2.0.0"} 0', result.stdout)
        self.assertIn('image_update_waiting_days{image="quay.io/example/app",current_version="v1.0.0",latest_version="v2.0.0"} -1', result.stdout)
        self.assertIn("image_report_last_success_timestamp_seconds ", result.stdout)

    def test_equal_digests_are_current_without_registry_calls(self):
        result = self.report("example/app\tstable@sha256:abc\tv2@sha256:abc", "tag_created() { exit 99; }; digest_created() { exit 99; }")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn('image_outdated_days{image="example/app",current_version="stable",latest_version="v2"} 0', result.stdout)

    def test_same_tag_with_different_digests_is_not_current(self):
        result = self.report("example/app\t1.0@sha256:old\t1.0@sha256:new", 'digest_created() { case "$2" in sha256:old) echo 1700000000 ;; *) echo 1700864000 ;; esac; }')
        self.assertIn('image_outdated_days{image="example/app",current_version="1.0",latest_version="1.0"} 10', result.stdout)

    def test_pinned_versions_are_dated_by_digest_not_mutable_tag(self):
        overrides = 'tag_created() { echo 1700864000; }; digest_created() { case "$2" in sha256:old) echo 1700000000 ;; *) echo 1700864000 ;; esac; }'
        result = self.report("example/app\t1@sha256:old\t2@sha256:new", overrides)
        self.assertIn('image_outdated_days{image="example/app",current_version="1",latest_version="2"} 10', result.stdout)

    def test_empty_source_fails_without_success_heartbeat(self):
        result = self.report("")
        self.assertNotEqual(0, result.returncode)
        self.assertNotIn("image_report_last_success_timestamp_seconds", result.stdout)

    def test_source_failure_fails_without_success_heartbeat(self):
        result = self.report("ignored", "series() { return 1; }")
        self.assertNotEqual(0, result.returncode)
        self.assertNotIn("image_report_last_success_timestamp_seconds", result.stdout)

    def test_implausible_latest_version_is_unknown(self):
        result = self.report("quay.io/jetstack/cert-manager-controller\tv1.16.2\t608111629")
        self.assertIn('latest_version="608111629"} -1', result.stdout)

    def test_subday_release_gap_does_not_erase_update_wait(self):
        result = self.report("example/app\t1.0\t1.1", 'tag_created() { case "$2" in 1.0) echo 1700000000 ;; *) echo 1700003600 ;; esac; }')
        line = next(line for line in result.stdout.splitlines() if line.startswith("image_update_waiting_days"))
        self.assertGreater(int(line.rsplit(" ", 1)[1]), 0)

    def source_rows(self, versions, failures):
        success = json.dumps({"status": "success", "data": {"result": versions}})
        failure = json.dumps({"status": "success", "data": {"result": failures}})
        overrides = 'curl() { case "$*" in *version_checker_image_failures_total*) printf "%s" ' + shlex.quote(failure) + ' ;; *) printf "%s" ' + shlex.quote(success) + ' ;; esac; }'
        prelude = script().split(': >"$WORK/out"', 1)[0]
        return subprocess.run(["bash"], input=prelude + "\n" + overrides + "\nseries\n", capture_output=True, text=True)

    def test_failure_of_new_tag_is_not_hidden_by_old_successful_tag(self):
        result = self.source_rows(
            [{"metric": {"image": "example/app", "current_version": "1", "latest_version": "1"}, "value": [0, "100"]}],
            [{"metric": {"image": "example/app:2"}, "value": [0, "200"]}],
        )
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("example/app\t1\t1", result.stdout)
        self.assertIn("example/app\t2\tunknown", result.stdout)

    def test_recent_failure_replaces_stale_success_for_same_reference(self):
        result = self.source_rows(
            [{"metric": {"image": "example/app", "current_version": "1", "latest_version": "1"}, "value": [0, "100"]}],
            [{"metric": {"image": "example/app:1"}, "value": [0, "200"]}],
        )
        self.assertEqual("example/app\t1\tunknown", result.stdout.strip())

    def test_recovery_supersedes_older_failure_for_same_reference(self):
        result = self.source_rows(
            [{"metric": {"image": "example/app", "current_version": "1", "latest_version": "1"}, "value": [0, "300"]}],
            [{"metric": {"image": "example/app:1"}, "value": [0, "200"]}],
        )
        self.assertEqual("example/app\t1\t1", result.stdout.strip())

    def test_registry_failure_images_are_reported_as_unknown(self):
        overrides = '''curl() {
          case "$*" in
            *version_checker_image_failures_total*) printf '%s' '{"status":"success","data":{"result":[{"metric":{"image":"ghcr.io/example/app:1.2@sha256:abc"},"value":[0,"3"]}]}}' ;;
            *) printf '%s' '{"status":"success","data":{"result":[]}}' ;;
          esac
        }'''
        prelude = script().split(': >"$WORK/out"', 1)[0]
        result = subprocess.run(["bash"], input=prelude + "\n" + overrides + "\nseries\n", capture_output=True, text=True)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("ghcr.io/example/app\t1.2@sha256:abc\tunknown", result.stdout.strip())

    def test_dashboard_includes_failed_lookups_and_collection_health(self):
        path = ROOT / "kubernetes/grafana/image-versions-dashboard.yml"
        dashboard = json.loads(yaml.safe_load(path.read_text())["data"]["image-versions.json"])
        self.assertIn("image_version_lookup_success", dashboard["templating"]["list"][0]["query"]["query"])
        exprs = " ".join(target["expr"] for panel in dashboard["panels"] for target in panel.get("targets", []))
        self.assertIn("image_report_last_success_timestamp_seconds", exprs)
        self.assertIn("image_report_timestamp_seconds", exprs)
        self.assertIn("version_checker_image_failures_total", exprs)

    @unittest.skipUnless(os.environ.get("IMAGE_REPORT_TEST_VM"), "local VictoriaMetrics integration endpoint not configured")
    def test_dashboard_newer_failure_supersedes_old_zero(self):
        url = os.environ["IMAGE_REPORT_TEST_VM"]
        self.assertRegex(url, r"^http://127\.0\.0\.1:[0-9]+$")
        now = int(time.time())
        lines = []
        for version, value, timestamp in [("2", 0, now - 3600), ("3", -1, now - 60)]:
            labels = f'image="test/report-freshness",current_version="1",latest_version="{version}"'
            lines.extend([
                f"image_report_timestamp_seconds{{{labels}}} {timestamp} {timestamp * 1000}",
                f"image_update_waiting_days{{{labels}}} {value} {timestamp * 1000}",
            ])
        upload = subprocess.run(["curl", "-fsS", "-X", "POST", "--data-binary", "@-", url + "/api/v1/import/prometheus"], input="\n".join(lines) + "\n", text=True, capture_output=True)
        self.assertEqual(0, upload.returncode, upload.stderr)
        subprocess.run(["curl", "-fsS", url + "/internal/force_flush"], check=True, capture_output=True)
        dashboard = json.loads(yaml.safe_load((ROOT / "kubernetes/grafana/image-versions-dashboard.yml").read_text())["data"]["image-versions.json"])
        card = next(panel for panel in dashboard["panels"] if panel["id"] == 1)
        query = card["targets"][0]["expr"].replace("$image", "test/report-freshness")
        result = subprocess.run(["curl", "-fsS", "-G", url + "/api/v1/query", "--data-urlencode", "query=" + query], capture_output=True, text=True, check=True)
        rows = json.loads(result.stdout)["data"]["result"]
        self.assertEqual(1, len(rows))
        self.assertEqual("-1", rows[0]["value"][1])
        self.assertEqual("3", rows[0]["metric"]["latest_version"])

    def test_registry_dates_use_coreutils_in_cronjob(self):
        command = documents()[1]["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["args"][0]
        self.assertIn("coreutils", command)
        for stamp in ["2026-11-24T19:50:11.49616Z", "Fri, 26 Jun 2026 09:57:35 -0000"]:
            result = subprocess.run(["date", "-u", "-d", stamp, "+%s"], capture_output=True, text=True)
            self.assertEqual(0, result.returncode, result.stderr)


if __name__ == "__main__":
    unittest.main()
