// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/UniswapERC20Swapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "@uniswap/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/contracts/interfaces/IWETH.sol";

contract UniswapERC20SwapperTest is Test {
    UniswapERC20Swapper swapper;
    ERC20Mock token;
    IUniswapV2Router02 uniswapRouter;
    IWETH weth;

    address constant UNISWAP_ROUTER = address(0); // Add the address of Uniswap Router for the testnet/mainnet

    function setUp() public {
        // Deploy a mock ERC20 token
        token = new ERC20Mock(
            "Mock Token",
            "MTK",
            address(this),
            1000000 * 10 ** 18
        );

        // Initialize the Uniswap router and WETH contract
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER);
        weth = IWETH(uniswapRouter.WETH());

        // Deploy the UniswapERC20Swapper contract
        swapper = new UniswapERC20Swapper(
            address(uniswapRouter),
            address(0),
            false
        );

        // Mint some WETH to the contract
        weth.deposit{value: 100 ether}();

        // Approve the Uniswap router to spend the WETH
        weth.approve(address(uniswapRouter), type(uint256).max);
    }

    function testSwapEtherToToken() public {
        // Mint some tokens to the contract
        token.mint(address(this), 10000 * 10 ** 18);

        // Approve the Uniswap router to spend the tokens
        token.approve(address(uniswapRouter), type(uint256).max);

        // Add liquidity to the Uniswap pool
        uniswapRouter.addLiquidityETH{value: 10 ether}(
            address(token),
            1000 * 10 ** 18,
            0,
            0,
            address(this),
            block.timestamp + 15 minutes
        );

        // Swap ETH for tokens
        uint minAmount = 1 * 10 ** 18; // Minimum amount of tokens to receive
        uint amountReceived = swapper.swapEtherToToken{value: 1 ether}(
            address(token),
            minAmount
        );

        // Check the balance of tokens received
        uint balance = token.balanceOf(address(this));
        assertEq(balance, amountReceived);
    }

    function testSetUniswapRouter() public {
        address newRouter = address(0x123);
        swapper.setUniswapRouter(newRouter);
        assertEq(address(swapper.uniswapRouter()), newRouter);
    }

    function testTogglePriceFeed() public {
        swapper.togglePriceFeed(true);
        assertTrue(swapper.priceFeedOn());
        swapper.togglePriceFeed(false);
        assertFalse(swapper.priceFeedOn());
    }
}
