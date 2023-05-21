# SimpleSwap
Implement a simple AMM swap (0% fee ratio) contract in `contracts/SimpleSwap.sol`. You must override all the external functions of `ISimpleSwap.sol`, and pass all the tests in `test/SimpleSwap.spec.ts`.

Suggest reading the `natSpec` of `ISimpleSwap.sol` first and then implementing the contract. If you are not sure what the function is about, feel free to discuss it in the Discord channel.

Reference:
- UniswapV2-core: https://github.com/Uniswap/v2-core
- UniswapV2-periphery: https://github.com/Uniswap/v2-periphery


## Local Development

Clone this repository and use the following code to build

``` bash
cd Blockchain-Resource/section3/SimpleSwap
forge install
forge remappings > remappings.txt
forge build
forge test
```
