# Running the Liquidation Bot Locally

## Quick Start

1. **Install dependencies**: `foundryup && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
2. **Build contracts**: `forge build && cd lib/evk-periphery && forge build && cd ../..`
3. **Create `.env` file** with required environment variables (see below)
4. **Run**: `python application.py`

The bot will start monitoring and expose a Flask API on port 8080.

## Prerequisites

1. **Foundry** - Install from [Foundry Book](https://book.getfoundry.sh/)
2. **Python 3** (with venv support)
3. **RPC Access** - You'll need RPC URLs for the chains you want to monitor

## Setup Steps

### 1. Install Dependencies

```bash
# Install Foundry (if not already installed)
foundryup

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Build contracts
forge install && forge build
cd lib/evk-periphery && forge build && cd ../..

# Create necessary directories
mkdir -p logs state
```

### 2. Create `.env` File

Create a `.env` file in the project root with the following environment variables:

#### REQUIRED Environment Variables:

```bash
# Liquidator EOA (the account that will execute liquidations)
LIQUIDATOR_EOA=0xYourEOAAddress
LIQUIDATOR_PRIVATE_KEY=0xYourPrivateKey

# RPC URLs - Based on which chain you're monitoring
# The variable name must match the RPC_NAME in config.yaml for your chain

# For HyperEVM (chain 999):
HYPEREVM_MAINNET_RPC_URL=https://your-rpc-url-here

# For Ethereum Mainnet (chain 1):
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

# For Base (chain 8453):
BASE_RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY

# For Swell (chain 1923):
SWELL_RPC_URL=https://your-rpc-url-here

# For Sonic (chain 146):
SONIC_RPC_URL=https://your-rpc-url-here

# For BOB (chain 60808):
BOB_RPC_URL=https://your-rpc-url-here

# For Berachain (chain 80094):
BERA_RPC_URL=https://your-rpc-url-here

# Mainnet RPC (ALWAYS REQUIRED - used for price oracles)
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
```

#### OPTIONAL Environment Variables:

```bash
# Slack notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
RISK_DASHBOARD_URL=https://your-dashboard-url.com

# GlueX API (if using GlueX swaps)
GLUEX_API_URL=https://api.gluex.com
GLUEX_API_KEY=your-api-key
GLUEX_UNIQUE_PID=your-unique-pid
```

### 3. Configure `config.yaml`

The `app/config.yaml` file should already have chain configurations. Make sure:
- Contract addresses are correct for your chain
- ABI paths point to the correct compiled contract files
- Chain-specific settings match your deployment

### 4. Update Chain IDs in `app/__init__.py`

Edit `app/__init__.py` to specify which chains to monitor:

```python
chain_ids = [999]  # Change to your desired chain ID(s)
# Examples: [999] for HyperEVM
```

### 5. Configure Bot Behavior

In `app/liquidation/routes.py`, you can control bot behavior:

```python
chain_manager = ChainManager(chain_ids, notify=True, execute_liquidation=False)
```

- `notify=True`: Send Slack notifications (requires SLACK_WEBHOOK_URL)
- `execute_liquidation=False`: Set to `True` to actually execute liquidations (be careful!)

## Running the Bot

### Start the Flask App

```bash
# Make sure you're in the virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Run the Flask app
python application.py
```

Or using Flask directly:

```bash
flask run --port 8080
```

The bot will:
1. Start the Flask server on port 8080
2. Begin monitoring the specified chains
3. Batch process historical `AccountStatusCheck` events on startup
4. Start periodic account health checks

### API Endpoints

Once running, you can access:

- **Health Check**: `http://localhost:8080/health`
- **All Positions**: `http://localhost:8080/liquidation/allPositions?chainId=999`

## Troubleshooting

### Missing RPC URL Error

If you see: `Env var HYPEREVM_MAINNET_RPC_URL not found`

Make sure your `.env` file has the correct RPC URL variable name matching what's in `config.yaml`:
- Check `config.yaml` for the `RPC_NAME` field for your chain
- Ensure the corresponding environment variable exists in `.env`

### Missing Contract ABIs

If you see ABI-related errors:
```bash
# Rebuild contracts
forge build
cd lib/evk-periphery && forge build && cd ../..
```

### Missing Directories

```bash
mkdir -p logs state
```

### Bot Not Finding Accounts

- Check that `EVC_DEPLOYMENT_BLOCK` in `config.yaml` is correct
- Verify the EVC contract address is correct
- Ensure your RPC URL is working and can query the chain

## Safety Notes

⚠️ **IMPORTANT**: 
- Start with `execute_liquidation=False` to test monitoring without executing liquidations
- Ensure your `LIQUIDATOR_PRIVATE_KEY` has sufficient funds for gas
- Test on testnets first if possible
- Monitor the logs in the `logs/` directory

## Logs and State

- **Logs**: Saved to `logs/{chain_name}_monitor.log`
- **State**: Saved to `state/{chain_name}_state.json` (allows bot to resume after restart)

