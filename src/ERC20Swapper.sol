// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ERC20Swapper {
    /// @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
    /// @param token The address of ERC-20 token to swap
    /// @param minAmount The minimum amount of tokens transferred to msg.sender
    /// @return The actual amount of transferred tokens
    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable returns (uint);
}

/**
 * @title ERC20Swapper
 * @dev Paul Ilves-Fomichov
 */
contract MyERC20Swapper is ERC20Swapper, Ownable2Step {
    IUniswapV2Router02 public uniswapRouter;
    AggregatorV3Interface internal priceFeed;

    event UniswapRouterChanged(
        address indexed oldRouter,
        address indexed newRouter
    );

    constructor(address _uniswapRouter) Ownable(msg.sender) {
        require(_uniswapRouter != address(0), "DeX address cannot be zero");
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable override returns (uint) {
        require(msg.value > 0, "Cannot send 0 ETH");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(minAmount, path, msg.sender, block.timestamp + 15 minutes);

        uint amountReceived = amounts[1];
        require(amountReceived >= minAmount, "Output amount < min");

        return amountReceived;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        require(_uniswapRouter != address(0), "DeX address cannot be zero");
        address oldRouter = address(uniswapRouter);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterChanged(oldRouter, _uniswapRouter);
    }
}
