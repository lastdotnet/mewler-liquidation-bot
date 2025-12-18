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

        vm.startPrank(deployer);

        SwapVerifier swapVerifier = new SwapVerifier();
        GluexGsmSwapper gluexGsmSwapper = new GluexGsmSwapper(EVC, deployer, GSM);
        GluexGsmLiquidator gluexGsmLiquidator = new GluexGsmLiquidator(deployer, address(gluexGsmSwapper), address(swapVerifier), EVC, PYTH);

        vm.stopPrank();
        
        // address swapperAddress = 0x7Ad9b79921D949C6dD6bA1384fE6884F9dFaFe09;
        // address liquidatorContract = 0x7D1c33cfD2637b3112893F058Ca2bEaDEad0a9F4;
        
        // Get the current Swapper owner and transfer ownership to liquidator contract
        Ownable swapper = Ownable(address(gluexGsmSwapper));
        address currentOwner = swapper.owner();
        
        // Transfer Swapper ownership to liquidator contract
        vm.startPrank(currentOwner);
        swapper.transferOwnership(address(gluexGsmLiquidator));
        vm.stopPrank();
        
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