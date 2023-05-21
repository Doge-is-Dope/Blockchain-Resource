// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ISimpleSwap} from "./interface/ISimpleSwap.sol";
import "./SimpleSwapLib.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    address private _tokenA; // The address of tokenA
    address private _tokenB; // The address of tokenB

    /// @dev Create a pair along with a ERC20 token
    constructor(address tokenA, address tokenB) ERC20("SimpleSwap", "SS") {
        require(Address.isContract(tokenA), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(Address.isContract(tokenB), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        (_tokenA, _tokenB) = SimpleSwapLib.sortTokens(tokenA, tokenB);
    }

    /// @dev Add liquidity to the pool
    function addLiquidity(uint256 amountAIn, uint256 amountBIn)
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (uint256 reserveA, uint256 reserveB) = getReserves();

        // If the pool is empty, then the amount in shall be greater than 0
        if (reserveA == 0 && reserveB == 0) {
            require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
            (amountA, amountB) = (amountAIn, amountBIn);
        } else {
            // Calculate the amount of tokenA and tokenB to be added to the pool
            uint256 amountBOptimal = SimpleSwapLib.quote(amountAIn, reserveA, reserveB);
            if (amountBOptimal <= amountBIn) {
                (amountA, amountB) = (amountAIn, amountBOptimal);
            } else {
                uint256 amountAOptimal = SimpleSwapLib.quote(amountBIn, reserveB, reserveA);
                assert(amountAOptimal <= amountAIn);
                (amountA, amountB) = (amountAOptimal, amountBIn);
            }
        }

        liquidity = Math.sqrt(amountA * amountB);

        // Transfer tokenA and tokenB from the msg sender to the contract
        ERC20(_tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(_tokenB).transferFrom(msg.sender, address(this), amountB);

        // Mint liquidity to the msg sender
        _mintLPToken(msg.sender, liquidity);
        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @dev Remove liquidity from the pool
    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        // Check if the liquidity is valid
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        uint256 reserveA;
        uint256 reserveB;
        (reserveA, reserveB) = getReserves();

        // Calculate the amount of tokenA and tokenB to be removed from the pool
        uint256 totalSupply = totalSupply();
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;

        // Transfer tokenA and tokenB from the contract to the msg sender
        ERC20(_tokenA).transfer(msg.sender, amountA);
        ERC20(_tokenB).transfer(msg.sender, amountB);

        // Burn liquidity from the msg sender
        _burnLPToken(msg.sender, liquidity);
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    /// @dev Get the reserves of the pool (tokenA and tokenB)
    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = ERC20(_tokenA).balanceOf(address(this));
        reserveB = ERC20(_tokenB).balanceOf(address(this));
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == _tokenA || tokenIn == _tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == _tokenA || tokenOut == _tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        // Get the reserves of the pool
        (uint256 reserveA, uint256 reserveB) = getReserves();
        // Calculate the resrve by the order
        (address token0,) = SimpleSwapLib.sortTokens(tokenIn, tokenOut);
        (uint256 reserve0, uint256 reserve1) = tokenIn == token0 ? (reserveA, reserveB) : (reserveB, reserveA);

        // Once the tokenIn with amountIn is transferred to the contract, the amountOut can be calculated
        // amountOut = SimpleSwapLib.quote(amountIn, reserve0, reserve1);
        amountOut = SimpleSwapLib.getAmountOut(amountIn, reserve0, reserve1);

        // Transfer tokenIn from the msg sender to the contract
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // Transfer tokenOut from the contract to the msg sender
        ERC20(tokenOut).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    function getTokenA() external view returns (address tokenA) {
        tokenA = _tokenA;
    }

    function getTokenB() external view returns (address tokenB) {
        tokenB = _tokenB;
    }

    /// @dev Mint the liquidity to the user
    function _mintLPToken(address owner, uint256 liquidity) internal {
        _mint(owner, liquidity);
    }

    /// @dev Transfer the liquidity to the contract and burn it afterwards
    function _burnLPToken(address owner, uint256 liquidity) internal {
        _transfer(owner, address(this), liquidity);
        _burn(address(this), liquidity);
        emit Transfer(address(this), address(0), liquidity);
    }
}
