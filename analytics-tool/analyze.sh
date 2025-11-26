#!/bin/bash

# Default values
OUTPUT_DIR="./output"
BINARY="ken"
URLPATH="/var/kend/data/klay.ipc"  # Default to IPC socket

# For api command
#NUMBER="77414400" # Uncomment it when you want to specify it and replace with your own value.
#BLOCKHASH="" # Uncomment it when you want to specify it and replace with your own value.
#TXHASH="" # Uncomment it when you want to specify it and replace with your own value.
#ACCOUNT="" # Uncomment it when you want to specify it and replace with your own value.

# For decode command
#NUMBER="170572052" # Uncomment it when you want to specify it and replace with your own value.
#KEYSTORE_FILE="local-deploy/homi-output/keys/keystore1" # Uncomment it when you want to specify it and replace with your own value.
#PASSWORD=$(cat local-deploy/homi-output/keys/passwd1)

# For common analysis
LINES=10000
LOG_PATH="/var/kend/logs/kend.out"
MONITOR_PORT=61006
METRICS_INTERVAL=5  # seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help message
usage() {
    echo "Usage: $0 [command]"
    echo "commands:"
    echo "  api     - Collect API information (latest, or filtered by NUMBER/BLOCKHASH/TXHASH)"
    echo "  common  - Collect common analysis data (logs, monitor metrics, system metrics)"
    echo "  decode  - Decode data using NUMBER or KEYSTORE_FILE&PASSWORD"
    echo "  help    - Show this help message"
    exit 1
}

# Helper function to format API call output
format_api_output() {
    local api_name=$1
    local api_call=$2
    local result
    
    echo ""
    echo "=========================================="
    echo "API: $api_name"
    echo "Call: $api_call"
    echo "------------------------------------------"
    
    result=$($BINARY attach --exec "$api_call" "$URLPATH" 2>/dev/null)
    
    if [ -n "$result" ] && [ "$result" != "undefined" ] && [ "$result" != "null" ]; then
        # Try to format as JSON if possible
        if echo "$result" | jq . >/dev/null 2>&1; then
            echo "$result" | jq .
        else
            echo "$result"
        fi
    else
        echo "Error: No result or call failed"
    fi
    echo "=========================================="
    echo ""
}

# Collect API information
collect_api_data() {
    local output_dir="$OUTPUT_DIR"
    mkdir -p "$output_dir"
    
    echo -e "${GREEN}Collecting API data...${NC}"
    
    local output_file="$output_dir/api_results.log"
    
    {
        echo "=================================================================================="
        echo "API Data Collection Report"
        echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "ChainId: $($BINARY attach --exec "kaia.chainId" $URLPATH)"
        echo "URLPath: $URLPATH"
        echo "kaia.blockNumber: $($BINARY attach --exec "kaia.blockNumber" $URLPATH)"
        echo "=================================================================================="
        echo ""

        
        # If NUMBER is specified, collect APIs that accept NUMBER
        if [ -n "$NUMBER" ]; then
            echo ">>> Collecting APIs for BLOCK NUMBER: $NUMBER"
            echo ""
            
            format_api_output "kaia.getParams" "kaia.getParams($NUMBER)"
            format_api_output "kaia.getChainConfig" "kaia.getChainConfig($NUMBER)"
            format_api_output "kaia.getBlock" "kaia.getBlock($NUMBER)"
            format_api_output "kaia.getBlockWithConsensusInfo" "kaia.getBlockWithConsensusInfo($NUMBER)"
            format_api_output "kaia.getBlockReceipts" "kaia.getBlockReceipts($NUMBER)"
            format_api_output "kaia.getCommittee" "kaia.getCommittee($NUMBER)"
            format_api_output "kaia.getCommitteeSize" "kaia.getCommitteeSize($NUMBER)"
            format_api_output "istanbul.getValidators" "istanbul.getValidators($NUMBER)"
            format_api_output "istanbul.getDemotedValidators" "istanbul.getDemotedValidators($NUMBER)"
            format_api_output "governance.getStakingInfo" "governance.getStakingInfo($NUMBER)"
            
        # If BLOCKHASH is specified, collect APIs that accept BLOCKHASH
        elif [ -n "$BLOCKHASH" ]; then
            echo ">>> Collecting APIs for BLOCK HASH: $BLOCKHASH"
            echo ""
            
            format_api_output "kaia.getBlock" "kaia.getBlock('$BLOCKHASH')"
            format_api_output "kaia.getBlockWithConsensusInfo" "kaia.getBlockWithConsensusInfo('$BLOCKHASH')"
            format_api_output "kaia.getBlockReceipts" "kaia.getBlockReceipts('$BLOCKHASH')"
            
        # If TXHASH is specified, collect APIs that accept TXHASH
        elif [ -n "$TXHASH" ]; then
            echo ">>> Collecting APIs for TRANSACTION HASH: $TXHASH"
            echo ""
            
            format_api_output "kaia.getTransactionReceipt" "kaia.getTransactionReceipt('$TXHASH')"
            
        # If ACCOUNT is specified, collect APIs that accept ACCOUNT
        elif [ -n "$ACCOUNT" ]; then
            echo ">>> Collecting APIs for ACCOUNT: $ACCOUNT"
            echo ""
            
            format_api_output "kaia.getAccount" "kaia.getAccount('$ACCOUNT')"
            
        # Default: collect latest information
        else
            echo ">>> Collecting LATEST information"
            echo ""
            
            format_api_output "admin.nodeConfig" "admin.nodeConfig"
            format_api_output "kaia.getParams" "kaia.getParams('latest')"
            format_api_output "kaia.getChainConfig" "kaia.getChainConfig('latest')"
            format_api_output "governance.status" "governance.status"
            format_api_output "debug.getBadBlocks" "debug.getBadBlocks()"
            format_api_output "kaia.getBlock" "kaia.getBlock('latest')"
            format_api_output "kaia.getBlockWithConsensusInfo" "kaia.getBlockWithConsensusInfo('latest')"
            format_api_output "kaia.getBlockReceipts" "kaia.getBlockReceipts('latest')"
            format_api_output "kaia.syncing" "kaia.syncing"
            format_api_output "admin.peers" "admin.peers"
            format_api_output "admin.nodeInfo" "admin.nodeInfo"
            format_api_output "kaia.getCommittee" "kaia.getCommittee('latest')"
            format_api_output "kaia.getCommitteeSize" "kaia.getCommitteeSize('latest')"
            format_api_output "istanbul.getValidators" "istanbul.getValidators('latest')"
            format_api_output "istanbul.getDemotedValidators" "istanbul.getDemotedValidators('latest')"
            format_api_output "governance.getStakingInfo" "governance.getStakingInfo('latest')"
            format_api_output "governance.idxCache" "governance.idxCache"
        fi
        
        echo ""
        echo "=================================================================================="
        echo "Collection completed at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "=================================================================================="
    } > "$output_file"
    
    echo -e "${GREEN}API data collected. Results saved to $output_file${NC}"
}

# Collect logs
collect_logs() {
    local output_dir="$OUTPUT_DIR/logs"
    mkdir -p "$output_dir"
    
    echo -e "${GREEN}Collecting the last ${LINES} lines from logs...${NC}"
    
    if [ -f "$LOG_PATH" ]; then
        tail -n "$LINES" "$LOG_PATH" > "$output_dir/latest.log"
        echo -e "${GREEN}Logs saved to $output_dir/latest.log${NC}"
    else
        echo -e "${YELLOW}Warning: Log file $LOG_PATH not found${NC}"
    fi
}

# Collect monitor metrics
collect_monitor_metrics() {
    echo -e "${GREEN}Collecting monitor metrics...${NC}"
    mkdir -p "$OUTPUT_DIR/monitor"
    
    curl -s "http://localhost:$MONITOR_PORT/metrics" > "$OUTPUT_DIR/monitor/monitor_metrics" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Monitor metrics saved to $OUTPUT_DIR/monitor/monitor_metrics${NC}"
    else
        echo -e "${YELLOW}Warning: Could not fetch monitor metrics from port $MONITOR_PORT${NC}"
    fi
}

# Collect system metrics
collect_system_metrics() {
    mkdir -p "$OUTPUT_DIR/system_metrics"
    local output_file="$OUTPUT_DIR/system_metrics/system_metrics.txt"
    
    echo -e "${GREEN}Collecting system metrics...${NC}"
    
    {
        echo "=== System Metrics Report ==="
        echo "Generated at: $(date)"
        echo ""
        
        echo "=== CPU Information ==="
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "N/A"
        else
            cat /proc/cpuinfo | grep "model name" | head -1 2>/dev/null || echo "N/A"
        fi
        echo ""
        
        echo "=== System Information ==="
        echo "** Memory Size:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sysctl -n hw.memsize 2>/dev/null | awk '{printf "  %.2f GB\n", $1 / 1024 / 1024 / 1024}' || echo "  N/A"
        else
            awk '/MemTotal/ {printf "  %.2f GB\n", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "  N/A"
        fi
        
        echo "** CPU Cores:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  Logical Cores: $(sysctl -n hw.logicalcpu 2>/dev/null || echo 'N/A')"
            echo "  Physical Cores: $(sysctl -n hw.physicalcpu 2>/dev/null || echo 'N/A')"
        else
            echo "  Logical Cores: $(nproc 2>/dev/null || echo 'N/A')"
            echo "  Physical Cores: $(lscpu 2>/dev/null | awk '/^Core\(s\) per socket:/ {print $4}' || echo 'N/A')"
        fi
        echo ""
        
        echo "=== Top Result ==="
        if [[ "$OSTYPE" == "darwin"* ]]; then
            top -l 1 -s 0 -o rsize 2>/dev/null | head -n 20 || echo "N/A"
        else
            top -b -n 1 2>/dev/null | head -n 20 || echo "N/A"
        fi
        echo ""
        
        echo "=== Disk Usage ==="
        df -h 2>/dev/null || echo "N/A"
        echo ""
        
        echo "=== Process Information ==="
        ps aux 2>/dev/null | grep -i "$BINARY" | grep -v grep || echo "No process found"
        echo ""
        
        echo "=== Killed System Logs ==="
        if [[ "$OSTYPE" == "darwin"* ]]; then
            log show --predicate 'eventMessage CONTAINS[c] "killed"' --info --last 1d 2>/dev/null || echo "N/A"
        else
            dmesg 2>/dev/null | grep -i 'killed process' || echo "No killed process found"
        fi
        echo ""
        
    } > "$output_file"
    
    echo -e "${GREEN}System metrics collected. Results saved to $output_file${NC}"
}

# Decode data
decode_data() {
    local output_dir="$OUTPUT_DIR"
    mkdir -p "$output_dir"
    
    echo -e "${GREEN}Decoding data...${NC}"
    
    # Check if jq is installed
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}Error: 'jq' is required for decode command. Please install it.${NC}"
        exit 1
    fi
    
    local output_file="$output_dir/decoded_data.log"
    
    {
        echo "=== Decoded Data ==="
        echo "Generated at: $(date)"
        echo ""
        
        # If NUMBER is specified, decode block data
        if [ -n "$NUMBER" ]; then
            echo "Block Number: $NUMBER"
            echo ""
            
            local block_response=$($BINARY attach --exec "JSON.stringify(kaia.getHeader($NUMBER))" "$URLPATH" | jq -r .)
            
            if [ -n "$block_response" ]; then
                echo "=== Block Data ==="
                echo "$block_response"
                echo ""
                
                # Decode vote data
                local vote_data=$(echo "$block_response" | jq -r '.voteData // empty')
                if [ -n "$vote_data" ] && [ "$vote_data" != "null" ] && [ "$vote_data" != "0x" ]; then
                    echo "=== Decoded Vote Data ==="
                    $BINARY util decode-vote "$vote_data" 2>/dev/null || echo "Failed to decode vote data"
                    echo ""
                fi
                
                # Decode governance data
                local gov_data=$(echo "$block_response" | jq -r '.governanceData // empty')
                if [ -n "$gov_data" ] && [ "$gov_data" != "null" ] && [ "$gov_data" != "0x" ]; then
                    echo "=== Decoded Governance Data ==="
                    $BINARY util decode-gov "$gov_data" 2>/dev/null || echo "Failed to decode governance data"
                    echo ""
                fi
                
                # Decode extra data
                local temp_file=$(mktemp)
                echo "$block_response" > "$temp_file" 2>/dev/null
                if [ -f "$temp_file" ]; then
                    echo "=== Decoded Extra Data ==="
                    $BINARY util decode-extra "$temp_file" 2>/dev/null || echo "Failed to decode extra data"
                    echo ""
                    rm -f "$temp_file"
                fi
            else
                echo "Error: Could not retrieve block data for number $NUMBER"
            fi
        elif [ -n "$KEYSTORE_FILE" ]; then
            echo "=== Decrypted KeyStore File ==="
            echo "KeyStore File: $KEYSTORE_FILE"
            echo "Password: $PASSWORD"
            $BINARY util decrypt-keystore "$KEYSTORE_FILE" "$PASSWORD" 2>/dev/null || echo "Failed to decrypt keystore file"
            echo ""
        else
            echo -e "${RED}Error: For decode command, you must specify either NUMBER or ACCOUNT${NC}"
            echo "Uncomment and set one of these variables in the script:"
            echo "  NUMBER=\"\""
            echo "  KEYSTORE_FILE=\"\""
            echo "  PASSWORD=\"\""
            exit 1
        fi
        
    } > "$output_file"
    
    echo -e "${GREEN}Decoded data saved to $output_file${NC}"
}

# Main execution
main() {
    # Parse command
    local command="${1:-help}"
     # Create output directory
    OUTPUT_DIR="$OUTPUT_DIR"/$command/$(date +%Y%m%d%H%M%S)
    mkdir -p "$OUTPUT_DIR"

    case "$command" in
        api)
            collect_api_data
            ;;
        common)
            collect_logs
            collect_monitor_metrics
            collect_system_metrics
            echo -e "${GREEN}Common analysis completed successfully!${NC}"
            ;;
        decode)
            decode_data
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            usage
            ;;
    esac
}

# Execute main
main "$@"
