// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {GluexGsmLiquidator} from "contracts/GluexGsmLiquidator.sol";
import {Liquidator} from "contracts/Liquidator.sol";
import {Script} from "forge-std/Script.sol";
import {Ownable} from "lib/evk-periphery/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {console} from "forge-std/console.sol";
import {GluexGsmSwapper} from "contracts/evk-periphery/Swaps/GluexGsmSwapper.sol";
import {SwapVerifier} from "contracts/SwapVerifier.sol";

contract Liquidate is Script {
    address constant GLUEX_ROUTER = 0xe95F6EAeaE1E4d650576Af600b33D9F7e5f9f7fd;
    address constant GSM = 0xcb17105F6A7A75D1F1C91317a4621d9AaAfe96Fd;
    address constant EVC = 0xceAA7cdCD7dDBee8601127a9Abb17A974d613db4;
    address constant PYTH = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;

    function run() public {
        // Fork at the block number when swap data was generated
        uint256 forkBlock = vm.envUint("SWAP_DATA_BLOCK_NUMBER");
        vm.createSelectFork(vm.envString("HYPEREVM_MAINNET_RPC_URL"), forkBlock);

        address deployer = vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        GluexGsmLiquidator gluexGsmLiquidator;
        address swapperAddress;
        GluexGsmSwapper gluexGsmSwapper;

        // Check if LIQUIDATOR_ADDRESS env var exists
        try vm.envAddress("LIQUIDATOR_ADDRESS") returns (address liquidatorAddr) {
            // Use existing liquidator contract
            console.log("Using existing liquidator at:", liquidatorAddr);
            gluexGsmLiquidator = GluexGsmLiquidator(liquidatorAddr);
            // Get swapper address from the liquidator contract
            swapperAddress = gluexGsmLiquidator.swapperAddress();
            console.log("Swapper address from liquidator:", swapperAddress);
        } catch {
            // Check if SWAPPER_ADDRESS env var exists
            try vm.envAddress("SWAPPER_ADDRESS") returns (address swapperAddr) {
                // Use existing swapper, deploy new liquidator
                console.log("Using existing swapper at:", swapperAddr);
                swapperAddress = swapperAddr;
                gluexGsmSwapper = GluexGsmSwapper(swapperAddr);
                
                vm.startPrank(deployer);
                SwapVerifier swapVerifier = new SwapVerifier();
                gluexGsmLiquidator = new GluexGsmLiquidator(deployer, swapperAddress, address(swapVerifier), EVC, PYTH);
                vm.stopPrank();

                console.log("Deployed new liquidator at:", address(gluexGsmLiquidator));
                console.log("Using existing swapper at:", swapperAddress);
            } catch {
                // Deploy new contracts
                console.log("LIQUIDATOR_ADDRESS and SWAPPER_ADDRESS not found, deploying new contracts");
                vm.startPrank(deployer);

                SwapVerifier swapVerifier = new SwapVerifier();
                gluexGsmSwapper = new GluexGsmSwapper(EVC, deployer, GSM);
                gluexGsmLiquidator = new GluexGsmLiquidator(deployer, address(gluexGsmSwapper), address(swapVerifier), EVC, PYTH);

                vm.stopPrank();

                swapperAddress = address(gluexGsmSwapper);
                console.log("Deployed new liquidator at:", address(gluexGsmLiquidator));
                console.log("Deployed new swapper at:", swapperAddress);
            }
        }

        // Get the current Swapper owner and transfer ownership to liquidator contract
        Ownable swapper = Ownable(address(gluexGsmSwapper));
        address currentOwner = swapper.owner();
        
        // Transfer Swapper ownership to liquidator contract
        vm.startPrank(currentOwner);
        swapper.transferOwnership(address(gluexGsmLiquidator));
        vm.stopPrank();

//         2025-12-19 06:02:31,213 - INFO - Liquidator: Handler bytes32: 0x3453b446d3286ae2686ce38071563c8524d9fc20f4b352e7e017a79fcbdbe658
// 2025-12-19 06:02:31,213 - INFO - Liquidator: SwapParams - handler: 0x3453b446d3286ae2686ce38071563c8524d9fc20f4b352e7e017a79fcbdbe658, mode: 0, account: 0x23726d4Ca9A3768A5102A49522a157a5825E7db8, tokenIn: 0x94e8396e0869c9F2200760aF0621aFd240E1CF38, tokenOut: 0x111111a1a0667d36bD57c0A9f569b98057111111, vaultIn: 0x64a3052570F5A1c241C6c8cd32F8F9aD411e6990, accountIn: 0x23726d4Ca9A3768A5102A49522a157a5825E7db8, accountOut: 0x23726d4Ca9A3768A5102A49522a157a5825E7db8, receiver: 0x23726d4Ca9A3768A5102A49522a157a5825E7db8, amountOut: 0, data length: 2176
        
        // address swapperAddress = 0x7Ad9b79921D949C6dD6bA1384fE6884F9dFaFe09;
        // address liquidatorContract = 0x7D1c33cfD2637b3112893F058Ca2bEaDEad0a9F4;
        

        
        // Use startPrank to impersonate the liquidator EOA for the liquidation call
        address liquidatorEOA = vm.envAddress("LIQUIDATOR_EOA");
        vm.startPrank(liquidatorEOA);

        // Parse swap data from comma-separated hex strings
        bytes[] memory swapData = new bytes[](1);
        swapData[0] = vm.envBytes("SWAP_DATA");

        gluexGsmLiquidator.liquidateSingleCollateral(
            Liquidator.LiquidationParams({
                violatorAddress: vm.envAddress("PARAMS_VIOLATOR_ADDRESS"),
                vault: vm.envAddress("PARAMS_VAULT_ADDRESS"),
                borrowedAsset: vm.envAddress("PARAMS_BORROWED_ASSET"),
                collateralVault: vm.envAddress("PARAMS_COLLATERAL_VAULT_ADDRESS"),
                collateralAsset: vm.envAddress("PARAMS_COLLATERAL_ASSET"),
                repayAmount: vm.envUint("PARAMS_MAX_REPAY"),
                seizedCollateralAmount: vm.envUint("PARAMS_SEIZED_COLLATERAL_SHARES"),
                receiver: vm.envAddress("PARAMS_PROFIT_RECEIVER")
            }),
            swapData
        );
        vm.stopPrank();
    }
}