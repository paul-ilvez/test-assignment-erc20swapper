// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/interfaces/IUniswapV2Router02.sol";

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
    AggregatorV3Interface public priceFeed;
    bool public priceFeedOn;
    uint public slippagePercent;

    /// @dev Emitted when the DeX router changes
    event DeXRouterChanged(
        address indexed oldRouter,
        address indexed newRouter
    );

    /// @dev Emitted when the Chainlink price feed changes
    event PriceFeedChanged(
        address indexed oldPriceFeed,
        address indexed newPriceFeed
    );

    // @dev Emitted when the slippage % changes
    event SlippageChanged(
        uint256 indexed oldSlippagePercent,
        uint256 indexed newSlippagePercent
    );

    /// @dev Note: pricefeed is off by default and for the purpose of demo's simplicity it is allowed to use a zero address
    /// @param _uniswapRouter address of the Uniswap V2 router
    /// @param _priceFeed address of the Chainlink price feed
    /// @param _slippagePercent the initial slippage value
    constructor(
        address _uniswapRouter,
        address _priceFeed,
        uint _slippagePercent
    ) Ownable(msg.sender) {
        require(_uniswapRouter != address(0), "DeX address cannot be zero");
        // require(_priceFeed != address(0), "Price feed address cannot be zero");
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        priceFeed = AggregatorV3Interface(_priceFeed);
        slippagePercent = _slippagePercent;
    }

    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable override returns (uint) {
        require(msg.value > 0, "Must send ETH to swap");

        if (priceFeedOn) {
            // Get the latest ETH price from the price feed
            (, int price, , , ) = priceFeed.latestRoundData();
            require(price > 0, "Invalid price from oracle");

            // Calculate the expected token amount from the oracle price
            uint expectedTokenAmount = (msg.value * uint(price)) / 1e8; // Chainlink price feeds have 8 decimals

            // Ensure the DEX rate is within an acceptable range (e.g., 1% slippage tolerance)
            uint slippageTolerance = (expectedTokenAmount * 1) / 100;
            require(
                minAmount >= expectedTokenAmount - slippageTolerance,
                "Slippage tolerance exceeded"
            );
        }

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;

        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(minAmount, path, msg.sender, block.timestamp + 15 minutes);

        uint amountReceived = amounts[1];
        require(amountReceived >= minAmount, "Insufficient output amount");

        return amountReceived;
    }

    /// @dev Updates the Uniswap router address.
    function setUniswapRouter(address _uniswapRouter) external onlyOwner {
        require(_uniswapRouter != address(0), "DeX address cannot be zero");
        address oldRouter = address(uniswapRouter);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit DeXRouterChanged(oldRouter, _uniswapRouter);
    }

    /// @dev Toggles price feed on/off
    function togglePriceFeed() external onlyOwner {
        priceFeedOn = !priceFeedOn;
    }

    /// @dev Updates the Chainlink price feed address
    function setPriceFeed(address _priceFeed) external onlyOwner {
        require(_priceFeed != address(0), "Price feed address cannot be zero");
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @dev Sets a new slippage %
    function setSlippagePercent(uint _slippagePercent) external onlyOwner {
        slippagePercent = _slippagePercent;
        emit SlippageChanged(_slippagePercent, slippagePercent);
    }
}
