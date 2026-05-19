#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/../.."

recent_limit_seconds=1800

friendly_name() {
  local name="$1"
  local email="$2"
  local identity
  identity="$(printf '%s <%s>' "$name" "$email" | tr '[:upper:]' '[:lower:]')"

  case "$identity" in
    *arnaud*|*bobume*)
      printf '%s\n' "Arnaud"
      ;;
    *carole*|*caromancie*)
      printf '%s\n' "Carole"
      ;;
    *)
      printf '%s\n' "$name"
      ;;
  esac
}

is_bot_identity() {
  local name="$1"
  local email="$2"
  local identity
  identity="$(printf '%s <%s>' "$name" "$email" | tr '[:upper:]' '[:lower:]')"

  case "$identity" in
    *"[bot]"*|*github-actions*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

format_age() {
  local seconds="$1"

  if [ "$seconds" -lt 60 ]; then
    printf 'il y a %s seconde(s)' "$seconds"
  elif [ "$seconds" -lt 3600 ]; then
    printf 'il y a %s minute(s)' "$((seconds / 60))"
  elif [ "$seconds" -lt 86400 ]; then
    printf 'il y a %s heure(s)' "$((seconds / 3600))"
  else
    printf 'il y a %s jour(s)' "$((seconds / 86400))"
  fi
}

echo "Verification de la synchro avec GitHub..."

if ! command -v git >/dev/null 2>&1; then
  echo "Git n'est pas disponible sur cet ordinateur."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Ce dossier n'est pas un depot Git."
  exit 1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"

if [ -z "$upstream" ]; then
  upstream="origin/$branch"
fi

echo "Branche locale: $branch"
echo "Reference GitHub: $upstream"
echo

if ! git fetch --quiet origin; then
  echo "Impossible de contacter GitHub pour le moment."
  echo "Verifie la connexion internet, puis relance ce script."
  exit 1
fi

if ! git rev-parse --verify "$upstream" >/dev/null 2>&1; then
  echo "La reference GitHub '$upstream' est introuvable."
  exit 1
fi

latest_commit="$(git rev-parse "$upstream")"
latest_git_author="$(git log -1 --format='%an' "$latest_commit")"
latest_git_email="$(git log -1 --format='%ae' "$latest_commit")"
latest_git_subject="$(git log -1 --format='%s' "$latest_commit")"
latest_git_timestamp="$(git log -1 --format='%ct' "$latest_commit")"
human_commit=""

while read -r commit_hash; do
  commit_author="$(git log -1 --format='%an' "$commit_hash")"
  commit_email="$(git log -1 --format='%ae' "$commit_hash")"

  if ! is_bot_identity "$commit_author" "$commit_email"; then
    human_commit="$commit_hash"
    break
  fi
done < <(git rev-list -n 30 "$upstream")

if [ -z "$human_commit" ]; then
  human_commit="$latest_commit"
fi

latest_author="$(git log -1 --format='%an' "$human_commit")"
latest_email="$(git log -1 --format='%ae' "$human_commit")"
latest_subject="$(git log -1 --format='%s' "$human_commit")"
latest_timestamp="$(git log -1 --format='%ct' "$human_commit")"
now_timestamp="$(date +%s)"
age_seconds="$((now_timestamp - latest_timestamp))"

if [ "$age_seconds" -lt 0 ]; then
  age_seconds=0
fi

latest_person="$(friendly_name "$latest_author" "$latest_email")"
latest_git_person="$(friendly_name "$latest_git_author" "$latest_git_email")"

if [ "$human_commit" != "$latest_commit" ]; then
  git_age_seconds="$((now_timestamp - latest_git_timestamp))"
  if [ "$git_age_seconds" -lt 0 ]; then
    git_age_seconds=0
  fi

  echo "Derniere modification automatique sur GitHub:"
  echo "- $(format_age "$git_age_seconds") par $latest_git_person"
  echo "- $latest_git_subject"
  echo
fi

echo "Derniere modification humaine sur GitHub:"
echo "- $(format_age "$age_seconds") par $latest_person"
echo "- $latest_subject"
echo

counts="$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || printf '0 0')"
set -- $counts
ahead="$1"
behind="$2"

if [ "$behind" -gt 0 ]; then
  echo "Action recommandee: faire 'git pull' avant de travailler."
  echo "Ton ordinateur a $behind commit(s) de retard sur GitHub."
else
  echo "Synchro: ton ordinateur est a jour avec GitHub."
fi

if [ "$ahead" -gt 0 ]; then
  echo "Attention: tu as $ahead commit(s) local(aux) non envoye(s) sur GitHub."
fi

if [ "$age_seconds" -lt "$recent_limit_seconds" ]; then
  echo "Indice: modification tres recente. $latest_person travaille peut-etre encore."
fi

if [ -n "$(git status --short)" ]; then
  echo
  echo "Attention: il y a des changements locaux non commit."
  git status --short
fi
