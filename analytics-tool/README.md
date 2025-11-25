# Kaia Analytics Tool

A command-line tool for collecting and analyzing node operation data.

There's three commands.
* `./analysis.sh api`
* `./analysis.sh common`
* `./analysis.sh decode`

## Prepare the script

Download the script inside your node:
```bash
curl -O https://raw.githubusercontent.com/kaiachain/kaiaspray/main/analytics-tool/analyze.sh
```

Make it executable:
```bash
chmod +x analyze.sh
```

## Replace the env variable with your own values
The env variables are located at the top of analyze.sh.

For all the cases, replace next env vars with your own values.
```bash
# At analyze.sh ln 4~7
OUTPUT_DIR="./output"
BINARY="ken"
URLPATH="/var/kend/data/klay.ipc"  # Default to IPC socket
```

For `api` command, you have five options.
1. [default], it returns `latest` information.
2. If you specify `NUMBER`, it only returns the API results which accepts NUMBER.
3. If you specify `BLOCKHASH`, it only returns the API results which accepts BLOCKHASH.
4. If you specify `TXHASH`, it only returns the API results which accepts TXHASH. 
5. If you specify `ACCOUNT`, it only returns the API results which accepts ACCOUNT.
```bash
# At analyze.sh line 9~11
#NUMBER="" # Uncomment it when you want to specify it and replace with your own value.
#BLOCKHASH="" # Uncomment it when you want to specify it and replace with your own value.
#TXHASH="" # Uncomment it when you want to specify it and replace with your own value.
#ACCOUNT="" # Uncomment it when you want to specify it and replace with your own value.
```

For `decode` command, you must specify either `NUMBER` or `KEYSTORE_FILE`&`PASSWORD`
```bash
# At analyze.sh line 14~15
#NUMBER="170572052" # Uncomment it when you want to specify it and replace with your own value.
#KEYSTORE_FILE="local-deploy/homi-output/keys/keystore1" # Uncomment it when you want to specify it and replace with your own value.
#PASSWORD=$(cat local-deploy/homi-output/keys/passwd1)
```

For `common` command, default setting is next. Replace with your own values.
```bash
# At analyze.sh ln 10~13
LINES=10000
LOG_PATH="/var/kend/logs/kend.out"
MONITOR_PORT=61006
METRICS_INTERVAL=5  # seconds
```

## Install dependencies
For `decode` command, `jq` needs to be installed.

## Run the script

```bash
./analyze.sh api
./analyze.sh common
./analyze.sh decode
```

It may need sudo.
```bash
sudo ./analyze.sh api
sudo ./analyze.sh common
sudo ./analyze.sh decode
```

## Export the output
The result is stored in output folder.
You can compress the output directory to zip file.
```bash
# NOTE: zip should be installed
zip -r output.zip output
```

You can upload the compressed zip file to s3.
```bash
# NOTE: aws-cli should be installed
ZIP_FILE=analytics-tool/output.zip
S3_BUCKET=
aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$ZIP_FILE"
```