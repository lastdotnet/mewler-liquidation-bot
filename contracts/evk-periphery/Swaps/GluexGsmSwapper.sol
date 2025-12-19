// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {SwapperOwnable, ISwapper} from "contracts/evk-periphery/Swaps/SwapperOwnable.sol";
import {SafeERC20Lib, IERC20} from "evk/EVault/shared/lib/SafeERC20Lib.sol";
import {IEVault} from "contracts/IEVault.sol";
import {IGsm} from "contracts/IGsm.sol";

contract GluexGsmSwapper is SwapperOwnable {
    address public immutable gsm;

    constructor(address _evc, address _owner, address _gsm) SwapperOwnable(_evc, _owner, address(0), address(0)) {
        gsm = _gsm;
    }
    
    /// @inheritdoc ISwapper
    function sweep(address token, uint256 amountMin, address to) public virtual override(SwapperOwnable) externalLock {
        // deposit underlying to gsm
        uint256 underlyingBalance = IERC20(IGsm(gsm).UNDERLYING_ASSET()).balanceOf(address(this));
        if (underlyingBalance > 0) {
            IGsm(gsm).sellAsset(underlyingBalance, address(this));
        }
        // sweep requested token balance
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance >= amountMin) {
            SafeERC20Lib.safeTransfer(IERC20(token), to, balance);
        }
    }
}