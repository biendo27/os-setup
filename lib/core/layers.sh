#!/usr/bin/env bash

if [[ -n "${OSSETUP_LAYERS_SH:-}" ]]; then
  return 0
fi
OSSETUP_LAYERS_SH=1

source "$OSSETUP_ROOT/lib/core/common.sh"

layers_core_manifest_path() {
  printf '%s\n' "$(ossetup_core_root)/manifests/layers/core.yaml"
}

layers_target_manifest_path() {
  local target="$1"
  printf '%s\n' "$(ossetup_core_root)/manifests/layers/targets/$target.yaml"
}

layers_host_manifest_path() {
  local host_id="$1"
  printf '%s\n' "$(ossetup_core_root)/manifests/layers/hosts/$host_id.yaml"
}

layers_user_manifest_path() {
  local user_id="$1"
  printf '%s\n' "$(ossetup_personal_root)/manifests/layers/users/$user_id.yaml"
}

layers_personal_host_manifest_path() {
  local host_id="$1"
  printf '%s\n' "$(ossetup_personal_root)/manifests/layers/hosts/$host_id.yaml"
}

normalize_host_id_auto() {
  local raw="$1"
  local normalized
  normalized="$(printf '%s' "${raw,,}" | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g')"
  printf '%s\n' "$normalized"
}

validate_host_id() {
  local host_id="$1"
  [[ "$host_id" =~ ^[a-z0-9][a-z0-9._-]{0,62}$ ]]
}

resolve_host_id() {
  local requested="${1:-auto}"
  local host_id

  if [[ "$requested" == "auto" ]]; then
    local hostname_raw
    hostname_raw="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"
    [[ -n "$hostname_raw" ]] || die "$E_PRECHECK" "could not resolve hostname for --host auto"
    host_id="$(normalize_host_id_auto "$hostname_raw")"
  else
    host_id="${requested,,}"
  fi

  if ! validate_host_id "$host_id"; then
    die "$E_USAGE" "invalid host id: $requested (allowed: [a-z0-9][a-z0-9._-]{0,62})"
  fi

  printf '%s\n' "$host_id"
}

merge_json_values() {
  local base_json="$1"
  local overlay_json="$2"

  jq -cn --argjson base "$base_json" --argjson overlay "$overlay_json" '
    def array_union($a; $b):
      reduce (($a + $b)[]) as $item
        ([]; if index($item) == null then . + [$item] else . end);

    def deep_merge($a; $b):
      if ($a | type) == "object" and ($b | type) == "object" then
        reduce (((($a | keys_unsorted) + ($b | keys_unsorted)) | unique)[] ) as $key
          ({};
            .[$key] = if ($a | has($key)) and ($b | has($key)) then
                        deep_merge($a[$key]; $b[$key])
                      elif ($b | has($key)) then
                        $b[$key]
                      else
                        $a[$key]
                      end
          )
      elif ($a | type) == "array" and ($b | type) == "array" then
        array_union($a; $b)
      else
        $b
      end;

    deep_merge($base; $overlay)
  '
}

resolve_layered_target_manifest_json() {
  local target="$1"
  local host_id="${2:-}"
  local core target_layer
  core="$(layers_core_manifest_path)"
  target_layer="$(layers_target_manifest_path "$target")"

  [[ -f "$core" ]] || die "$E_PRECHECK" "manifest missing: $core"
  [[ -f "$target_layer" ]] || die "$E_PRECHECK" "manifest missing: $target_layer"

  local merged
  merged="$(cat "$core")"
  merged="$(merge_json_values "$merged" "$(cat "$target_layer")")"

  if [[ -n "$host_id" ]]; then
    local core_host_layer
    core_host_layer="$(layers_host_manifest_path "$host_id")"
    if [[ -f "$core_host_layer" ]]; then
      merged="$(merge_json_values "$merged" "$(cat "$core_host_layer")")"
    fi
  fi

  if is_personal_workspace_mode; then
    local user_layer user_id
    user_id="$(workspace_user_id)"
    if [[ -n "$user_id" ]]; then
      user_layer="$(layers_user_manifest_path "$user_id")"
      if [[ -f "$user_layer" ]]; then
        merged="$(merge_json_values "$merged" "$(cat "$user_layer")")"
      fi
    fi

    if [[ -n "$host_id" ]]; then
      local personal_host_layer
      personal_host_layer="$(layers_personal_host_manifest_path "$host_id")"
      if [[ -f "$personal_host_layer" ]]; then
        merged="$(merge_json_values "$merged" "$(cat "$personal_host_layer")")"
      fi
    fi
  fi

  printf '%s\n' "$merged"
}

resolve_target_manifest_json() {
  local target="$1"
  local host_id="${2:-}"
  resolve_layered_target_manifest_json "$target" "$host_id"
}
