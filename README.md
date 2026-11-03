# Heartcron ping action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-Heartcron%20ping-blue?logo=github)](https://github.com/marketplace/actions/heartcron-ping)

Know when a scheduled GitHub Actions workflow fails, runs late or doesn’t run at all.

Scheduled workflows are easy to lose track of: GitHub can delay or drop runs under load, and it switches schedules off in repositories without activity for 60 days. A failed run only shows up if someone looks. This action pings [Heartcron](https://heartcron.com) at the start and end of a job, and Heartcron alerts you in Telegram, Slack, Discord or email when the result is a failure or when no ping arrives on schedule.

## Usage

1. Create a free account at [heartcron.com](https://heartcron.com) and add a cron check with the same schedule as your workflow (in UTC).
2. Save the check’s ping URL as a repository secret, for example `HEARTCRON_URL`.
3. Add two steps to the job:

```yaml
on:
  schedule:
    - cron: "17 3 * * *"

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: heartcron/ping-action@v1
        with:
          url: ${{ secrets.HEARTCRON_URL }}
          status: start

      - uses: actions/checkout@v4
      - run: ./scripts/sync.sh

      - uses: heartcron/ping-action@v1
        if: always()
        with:
          url: ${{ secrets.HEARTCRON_URL }}
          status: ${{ job.status }}
```

`if: always()` makes the last step run even when the job fails, so Heartcron hears about failures right away instead of waiting for the grace period.

## Inputs

| Input | Default | Description |
|---|---|---|
| `url` | | The check’s ping URL. Keep it in a secret. |
| `ping-key`, `slug` | | Instead of `url`: the project’s ping key and the check’s short name. |
| `status` | `success` | `start`, `success`, `fail`, `log`, an exit code `0`–`255`, or `${{ job.status }}` (`failure` and `cancelled` count as failures). |
| `body` | | Text attached to the ping. Up to 100 KB is kept on paid plans, 10 KB on Free. |
| `body-file` | | A file whose last 100 KB to attach, such as a log your job wrote. |
| `create` | `false` | With `ping-key` and `slug`: create the check on its first ping. |
| `base-url` | `https://ping.heartcron.com` | Ping endpoint for `ping-key` and `slug`. |
| `fail-on-error` | `false` | Fail the step when the ping can’t be delivered. By default it only prints a warning, so monitoring never breaks your workflow. |

## Attach a log

Write the job’s output to a file and pass it as `body-file`: the last 100 KB goes along with the ping and shows up on the check’s page in Heartcron.

```yaml
      - run: ./scripts/sync.sh 2>&1 | tee sync.log
      - uses: heartcron/ping-action@v1
        if: always()
        with:
          url: ${{ secrets.HEARTCRON_URL }}
          status: ${{ job.status }}
          body-file: sync.log
```

## Without the action

The action is a thin wrapper around one request, so you can also call it yourself:

```bash
curl -fsS -m 10 --retry 3 "$HEARTCRON_URL/start"   # job started
curl -fsS -m 10 --retry 3 "$HEARTCRON_URL"         # job succeeded
curl -fsS -m 10 --retry 3 "$HEARTCRON_URL/fail"    # job failed
```

More in the [Heartcron docs](https://heartcron.com/docs/) and the guide to [monitoring scheduled GitHub Actions](https://heartcron.com/guides/github-actions-schedule/).

## License

MIT
