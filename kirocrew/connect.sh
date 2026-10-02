#!/usr/bin/env bash
# ============================================================================
# connect.sh - one-command Kiro Crew onboarding from a VS Code server
#
# Run this in a terminal that has AWS credentials for the workshop account
# (e.g., the Workshop Studio VS Code server). It will:
#   1. Ensure the SSM Session Manager plugin is installed
#   2. Read the kirocrew stack outputs (instance, URL, passcode)
#   3. Run `kiro-cli login` on the Kiro Crew host, interactively - you click
#      the device-code URL and sign in with YOUR Kiro credentials
#   4. Finish Kiro Crew setup and restart the gateway
#   5. Mint a dashboard sign-in link and print ONE URL that both passes the
#      CloudFront passcode gate and signs you in
#
# Usage: ./connect.sh [--login-only | --url-only]
#   REGION / STACK env vars override the defaults below.
# ============================================================================
# Re-exec under bash if invoked via sh/dash (e.g., `sh connect.sh`).
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi
set -euo pipefail

REGION="${REGION:-us-east-1}"
STACK="${STACK:-kirocrew-deployment}"
MODE="${1:-full}"

say()  { echo -e "\n\033[1;36m==> $*\033[0m"; }
fail() { echo -e "\033[1;31mERROR: $*\033[0m" >&2; exit 1; }

# --- 1. Session Manager plugin ---------------------------------------------
if ! command -v session-manager-plugin >/dev/null 2>&1; then
  say "Installing the SSM Session Manager plugin..."
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  case "$(uname -m)" in
    aarch64|arm64) arch=ubuntu_arm64;;
    *)             arch=ubuntu_64bit;;
  esac
  curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${arch}/session-manager-plugin.deb" \
    -o "$tmp/ssm.deb"
  sudo dpkg -i "$tmp/ssm.deb" >/dev/null
  command -v session-manager-plugin >/dev/null || fail "plugin install failed"
fi

# --- 2. Stack outputs --------------------------------------------------------
say "Reading stack outputs ($STACK in $REGION)..."
out() {
  aws cloudformation describe-stacks --stack-name "$STACK" --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}
IID=$(out InstanceId);          [ -n "$IID" ]  || fail "stack/outputs not found"
URL=$(out CrewUrl)
PASS=$(out CrewPasscode)
echo "    Instance:  $IID"
echo "    Dashboard: $URL"
echo "    Passcode:  $PASS"

# Remote-exec helper: runs a command on the host via send-command, prints output.
remote() {
  local cid
  cid=$(aws ssm send-command --instance-ids "$IID" --region "$REGION" \
    --document-name AWS-RunShellScript \
    --parameters "commands=[\"$1\"]" \
    --query 'Command.CommandId' --output text)
  for _ in $(seq 1 30); do
    local st
    st=$(aws ssm get-command-invocation --command-id "$cid" --instance-id "$IID" \
      --region "$REGION" --query Status --output text 2>/dev/null || echo Pending)
    case "$st" in Success|Failed|Cancelled|TimedOut) break;; esac
    sleep 2
  done
  aws ssm get-command-invocation --command-id "$cid" --instance-id "$IID" \
    --region "$REGION" --query StandardOutputContent --output text
}

if [ "$MODE" != "--url-only" ]; then
  # --- 3. Kiro sign-in (interactive, your own credentials) -------------------
  say "Checking Kiro sign-in status on the host..."
  WHO=$(remote "sudo -iu ubuntu kiro-cli whoami 2>/dev/null || true")
  if echo "$WHO" | grep -qiE 'not logged|error|^$'; then
    say "Starting kiro-cli login - click the URL it prints and sign in with YOUR Kiro account."
    echo "    (The session ends automatically when login completes.)"
    aws ssm start-session --target "$IID" --region "$REGION" \
      --document-name AWS-StartInteractiveCommand \
      --parameters '{"command":["sudo -iu ubuntu kiro-cli login --use-device-flow"]}'
  else
    echo "    Already signed in: $(echo "$WHO" | head -1)"
  fi

  # --- 4. Finish setup + restart ---------------------------------------------
  say "Finalizing Kiro Crew setup..."
  remote "sudo -iu ubuntu bash -c '~/.local/bin/kirocrew setup' >/dev/null 2>&1 || true; systemctl reset-failed kirocrew 2>/dev/null || true; systemctl restart kirocrew" >/dev/null
  sleep 8
fi
[ "$MODE" = "--login-only" ] && { say "Login done."; exit 0; }

# --- 5. Mint the one-click URL ----------------------------------------------
say "Minting your dashboard sign-in link..."
# `kirocrew token` prints a localhost URL (http://localhost:9381?token=...);
# extract just the token value and build the public CloudFront link ourselves.
TOKEN=$(remote "sudo -iu ubuntu bash -c '~/.local/bin/kirocrew token'" \
  | grep -m1 -oE 'token=[A-Za-z0-9._-]+' | cut -d= -f2- || true)
[ -n "$TOKEN" ] || fail "could not mint a token - is the gateway running? (sudo journalctl -u kirocrew)"

# The gate strips 'passcode' and preserves 'token', so one URL does both.
FINAL="${URL}/?token=${TOKEN}&passcode=${PASS}"
# --- Colors for the highlighted output --------------------------------------
BOLD='\033[1m'; YELLOW='\033[1;33m'; GREEN='\033[1;32m'; DIM='\033[2m'; RST='\033[0m'

# OPTIONAL section FIRST (dimmed) so it scrolls up and out of the way...
echo
echo -e "${DIM}--- OPTIONAL: only if you are hosting others. Otherwise ignore this - just copy the link at the bottom. ---${RST}"
echo
echo -e "${DIM}Share with workshop participants:${RST}"
echo -e "${DIM}    Dashboard: ${URL}/?passcode=${PASS}${RST}"
echo -e "${DIM}    Passcode:  ${PASS}   (needed once per browser; cookie lasts 7 days)${RST}"
echo
echo -e "${DIM}Participants also need a sign-in link - mint one per person with:${RST}"
echo -e "${DIM}    ./connect.sh --url-only${RST}"
echo
echo -e "${DIM}If your link expires, re-run: ./connect.sh --url-only${RST}"

# ...and the one-click link LAST, so it stays at the bottom ready to copy.
echo
echo -e "${YELLOW}${BOLD}============================================================${RST}"
echo -e "${YELLOW}${BOLD}  >>> COPY THIS LINK  ---  open it within 5 minutes  <<<${RST}"
echo -e "${YELLOW}${BOLD}      (signs you in; session lasts up to 30 days)${RST}"
echo -e "${YELLOW}${BOLD}============================================================${RST}"
echo
echo -e "${GREEN}${BOLD}${FINAL}${RST}"
echo
echo -e "${YELLOW}${BOLD}============================================================${RST}"
