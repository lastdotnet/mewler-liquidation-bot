// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20, IERC4626} from "./IEVault.sol";
import {IWETH9} from "contracts/IWETH9.sol";
import {IEVault} from "contracts/IEVault.sol";

contract EVaultGateway {

    function deposit(address vault, address token, uint256 amount, address receiver) public {
        // transfer from msg.sender
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // deposit into the vault
        IERC20(token).approve(vault, 0);
        IERC20(token).approve(vault, amount);
        IEVault(vault).deposit(amount, receiver);
        IERC20(token).approve(vault, 0);
    }

    function mint(address vault, address token, uint256 amount, address receiver) public {
        // transfer from msg.sender
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(vault, 0);
        IERC20(token).approve(vault, amount);

        // mint vault shares
        uint256 shares = IEVault(vault).previewMint(amount);
        IEVault(vault).mint(shares, receiver);
        IERC20(token).approve(vault, 0);
    }

    function depositHYPE(address vault, address token, address receiver) public payable {
        // wrap native token
        IWETH9(payable(token)).deposit{value: msg.value}();
        
        // deposit into the vault
        IERC20(token).approve(vault, 0);
        IERC20(token).approve(vault, msg.value);
        IEVault(vault).deposit(msg.value, receiver);
        IERC20(token).approve(vault, 0);
    }

    function mintHYPE(address vault, address token, address receiver) public payable {
        // wrap native token
        IWETH9(payable(token)).deposit{value: msg.value}();
        IERC20(token).approve(vault, 0);
        IERC20(token).approve(vault, msg.value);
        
        // mint vault shares
        uint256 shares = IEVault(vault).previewMint(msg.value);
        IEVault(vault).mint(shares, receiver);
        IERC20(token).approve(vault, 0);
    }
}