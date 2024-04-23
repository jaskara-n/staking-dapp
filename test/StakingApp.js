const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("StakingApp", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployInit() {
    const [owner, otherAccount] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();
    const StakingApp = await ethers.getContractFactory("StakingApp");
    const stakingApp = await StakingApp.deploy(token.address);
    return { token, stakingApp, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right token contract address", async function () {
      const { token, stakingApp } = await loadFixture(deployInit);
      expect(await stakingApp.tokenAdd()).to.equal(token.address);
    });
  });
});
