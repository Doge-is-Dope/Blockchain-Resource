// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SimpleSwapLib {
    using SafeMath for uint256;

    /// @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SimpleSwap: ZERO_ADDRESS");
    }

    /// @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        uint256 numerator = amountIn.mul(reserveOut);
        uint256 denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }
}
