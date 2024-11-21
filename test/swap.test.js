const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BTXUSDCStableSwap", function () {
    let btxToken, usdcToken, stableSwap;
    let owner, user1, user2;

    const INITIAL_RATE = ethers.BigNumber.from("830"); // 830 BTX per 1 USDC 

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
    
        // Deploy BTXToken and USDCToken
        const BTXToken = await ethers.getContractFactory("BTXToken");
        btxToken = await BTXToken.deploy();
        await btxToken.deployed();

        await btxToken.connect(owner).functions["mint(address,uint256,bool)"](
            owner.address,
            ethers.utils.parseEther("100000000"),
            false
        );
    
        const USDCToken = await ethers.getContractFactory("USDCToken");
        usdcToken = await USDCToken.deploy();
        await usdcToken.deployed();
    
      
        // Deploy the stable swap contract
        const BTXUSDCStableSwap = await ethers.getContractFactory("BTXUSDCStableSwap");
        stableSwap = await BTXUSDCStableSwap.deploy(btxToken.address, usdcToken.address, INITIAL_RATE);
        await stableSwap.deployed();

        let btxAmount = await stableSwap.getBtxAmountForUsdc(ethers.utils.parseUnits("1", 6));
        console.log("BTX for 1 USDC:", ethers.utils.formatUnits(btxAmount, 18)); // Should be "830"
        
        let usdcAmount = await stableSwap.getUsdcAmountForBtx(ethers.utils.parseUnits("830", 18));
        console.log("USDC for 830 BTX:", ethers.utils.formatUnits(usdcAmount, 6)); // Should be "1"
        
    
        // Add liquidity
        await btxToken.transfer(stableSwap.address, ethers.utils.parseUnits("100000", 18));
        await usdcToken.transfer(stableSwap.address, ethers.utils.parseUnits("10000", 6));
    });

    describe("Initialization", function () {
        it("Should correctly initialize contract", async function () {
            expect(await stableSwap.btxToUsdcRate()).to.equal(INITIAL_RATE);
            expect(await btxToken.balanceOf(stableSwap.address)).to.equal(ethers.utils.parseUnits("100000", 18));
            expect(await usdcToken.balanceOf(stableSwap.address)).to.equal(ethers.utils.parseUnits("10000", 6));
        });
    });

    describe("Swapping BTX for USDC", function () {
        it("Should allow user to swap BTX for USDC", async function () {
            const btxAmount = ethers.utils.parseUnits("830", 18); // 830 BTX
            const expectedUsdcAmount = ethers.utils.parseUnits("1", 6); // 1 USDC

            // Transfer BTX to user1 and approve contract
            await btxToken.transfer(user1.address, btxAmount);
            await btxToken.connect(user1).approve(stableSwap.address, btxAmount);

            // Perform the swap
            await expect(stableSwap.connect(user1).swapBTXForUSDC(btxAmount))
                .to.emit(stableSwap, "BTXSwappedForUSDC")
                .withArgs(user1.address, btxAmount, expectedUsdcAmount);

            // Check balances
            expect(await btxToken.balanceOf(user1.address)).to.equal(0); // User1 sent BTX
            expect(await usdcToken.balanceOf(user1.address)).to.equal(expectedUsdcAmount); // User1 received USDC
        });

        it("Should revert if insufficient USDC liquidity", async function () {
            const btxAmount = ethers.utils.parseUnits("10000000", 18); // Large amount of BTX

            // Transfer BTX to user1 and approve contract
            await btxToken.transfer(user1.address, btxAmount);
            await btxToken.connect(user1).approve(stableSwap.address, btxAmount);

            let usdcAmount = await stableSwap.getUsdcAmountForBtx(btxAmount);
            console.log("USDC for large BTX:", ethers.utils.formatUnits(usdcAmount, 6)); // Should be "1"

            // Attempt to swap
            await expect(
                stableSwap.connect(user1).swapBTXForUSDC(btxAmount)
            ).to.be.revertedWith("Insufficient USDC liquidity in contract");
        });
    });

    describe("Swapping USDC for BTX", function () {
        it("Should allow user to swap USDC for BTX", async function () {
            const usdcAmount = ethers.utils.parseUnits("1", 6); // 1 USDC
            const expectedBtxAmount = ethers.utils.parseUnits("830", 18); // 830 BTX

            // Transfer USDC to user1 and approve contract
            await usdcToken.transfer(user1.address, usdcAmount);
            await usdcToken.connect(user1).approve(stableSwap.address, usdcAmount);

            // Perform the swap
            await expect(stableSwap.connect(user1).swapUSDCForBTX(usdcAmount))
                .to.emit(stableSwap, "USDCSwappedForBTX")
                .withArgs(user1.address, usdcAmount, expectedBtxAmount);

            // Check balances
            expect(await usdcToken.balanceOf(user1.address)).to.equal(0); // User1 sent USDC
            expect(await btxToken.balanceOf(user1.address)).to.equal(expectedBtxAmount); // User1 received BTX
        });

        it("Should revert if insufficient BTX liquidity", async function () {
            const usdcAmount = ethers.utils.parseUnits("50000", 6); // Large amount of USDC

            // Transfer USDC to user1 and approve contract
            await usdcToken.transfer(user1.address, usdcAmount);
            await usdcToken.connect(user1).approve(stableSwap.address, usdcAmount);

            // Attempt to swap
            await expect(
                stableSwap.connect(user1).swapUSDCForBTX(usdcAmount)
            ).to.be.revertedWith("Insufficient BTX liquidity in contract");
        });
    });

    describe("Admin Functions", function () {
        it("Should allow owner to update exchange rate", async function () {
            const newRate = ethers.BigNumber.from("900000000000000"); // 900 BTX per USDC
            await stableSwap.connect(owner).updateBTXToUSDCExchangeRate(newRate);
            expect(await stableSwap.btxToUsdcRate()).to.equal(newRate);
        });

        it("Should allow owner to withdraw tokens", async function () {
            const btxWithdrawAmount = ethers.utils.parseUnits("5000", 18);
            const usdcWithdrawAmount = ethers.utils.parseUnits("2000", 6);

            // Withdraw BTX
            await expect(stableSwap.connect(owner).withdrawBTX(btxWithdrawAmount, owner.address))
                .to.emit(btxToken, "Transfer")
                .withArgs(stableSwap.address, owner.address, btxWithdrawAmount);

            // Withdraw USDC
            await expect(stableSwap.connect(owner).withdrawUSDC(usdcWithdrawAmount, owner.address))
                .to.emit(usdcToken, "Transfer")
                .withArgs(stableSwap.address, owner.address, usdcWithdrawAmount);
        });
        it("Should allow pausing and prevent swaps when paused", async function () {
            // Pause the contract
            await stableSwap.connect(owner).pause();
        
            // Attempt a swap while paused
            await btxToken.transfer(user1.address, ethers.utils.parseEther("830"));
            await btxToken.connect(user1).approve(stableSwap.address, ethers.utils.parseEther("830"));
            await expect(
                stableSwap.connect(user1).swapBTXForUSDC(ethers.utils.parseEther("830"))
            ).to.be.revertedWith("Pausable: paused");
        
            // Unpause the contract
            await stableSwap.connect(owner).unpause();
        
            // Swap should now work
            await stableSwap.connect(user1).swapBTXForUSDC(ethers.utils.parseEther("830"));
          });
    });
});
