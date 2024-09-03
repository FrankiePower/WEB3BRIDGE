const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

describe("Airdrop", function () {
  let Airdrop, airdrop, Token, token, owner, addr1, addr2, addr3;
  let merkleTree, merkleRoot;

  before(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Deploy the ERC20 token
    Token = await ethers.getContractFactory("MockERC20");
    token = await Token.deploy("Mock Token", "MTK");

    // Create the Merkle tree
    const leaves = [
      { address: addr1.address, amount: ethers.parseEther("100") },
      { address: addr2.address, amount: ethers.parseEther("200") },
    ].map((x) =>
      ethers.solidityPackedKeccak256(
        ["address", "uint256"],
        [x.address, x.amount]
      )
    );

    merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    merkleRoot = merkleTree.getHexRoot();

    // Deploy the Airdrop contract
    Airdrop = await ethers.getContractFactory("Airdrop");
    airdrop = await Airdrop.deploy(token.target, merkleRoot);

    // Transfer tokens to the Airdrop contract
    await token.transfer(airdrop.target, ethers.parseEther("1000"));
  });

  describe("Deployment", function () {
    it("Should set the correct token and merkle root", async function () {
      expect(await airdrop.token()).to.equal(token.target);
      expect(await airdrop.merkleRoot()).to.equal(merkleRoot);
    });
  });

  describe("Claiming", function () {
    it("Should allow eligible users to claim", async function () {
      const leaf = ethers.solidityPackedKeccak256(
        ["address", "uint256"],
        [addr1.address, ethers.parseEther("100")]
      );
      const proof = merkleTree.getHexProof(leaf);

      await expect(
        airdrop.connect(addr1).claim(ethers.parseEther("100"), proof)
      )
        .to.emit(airdrop, "Claimed")
        .withArgs(addr1.address, ethers.parseEther("100"));

      expect(await token.balanceOf(addr1.address)).to.equal(
        ethers.parseEther("100")
      );
      expect(await airdrop.claimed(addr1.address)).to.be.true;
    });

    it("Should not allow double claiming", async function () {
      const leaf = ethers.solidityPackedKeccak256(
        ["address", "uint256"],
        [addr1.address, ethers.parseEther("100")]
      );
      const proof = merkleTree.getHexProof(leaf);

      await expect(
        airdrop.connect(addr1).claim(ethers.parseEther("100"), proof)
      ).to.be.revertedWith("Already claimed");
    });

    it("Should not allow claiming with invalid proof", async function () {
      const leaf = ethers.solidityPackedKeccak256(
        ["address", "uint256"],
        [addr3.address, ethers.parseEther("300")]
      );
      const proof = merkleTree.getHexProof(leaf);

      await expect(
        airdrop.connect(addr3).claim(ethers.parseEther("300"), proof)
      ).to.be.revertedWith("Invalid proof");
    });
  });

  describe("Admin functions", function () {
    it("Should allow owner to set new merkle root", async function () {
      const newMerkleRoot = ethers.randomBytes(32);
      await airdrop.setMerkleRoot(newMerkleRoot);
      expect(await airdrop.merkleRoot()).to.equal(
        ethers.hexlify(newMerkleRoot)
      );
    });

    it("Should not allow non-owner to set merkle root", async function () {
      const newMerkleRoot = ethers.randomBytes(32);
      await expect(
        airdrop.connect(addr1).setMerkleRoot(newMerkleRoot)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow owner to withdraw remaining tokens", async function () {
      const initialBalance = await token.balanceOf(owner.address);
      await airdrop.withdrawRemainingTokens();
      const finalBalance = await token.balanceOf(owner.address);
      expect(finalBalance).to.be.gt(initialBalance);
    });

    it("Should not allow non-owner to withdraw tokens", async function () {
      await expect(
        airdrop.connect(addr1).withdrawRemainingTokens()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
