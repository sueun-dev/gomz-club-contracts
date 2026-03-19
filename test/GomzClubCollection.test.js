const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('GomzClubCollection', function () {
  async function deployFixture() {
    const [owner, alice, bob, treasury] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory('GomzClubCollection');
    const contract = await Factory.deploy('ipfs://placeholder/hidden.json');
    await contract.deployed();

    return { contract, owner, alice, bob, treasury };
  }

  it('uses placeholder metadata before reveal and base URI after reveal', async function () {
    const { contract, owner, alice } = await deployFixture();

    await contract.seedWhitelist([alice.address], true);
    await contract.setSalePhase(1);
    await contract.connect(alice).mintWhitelist(1, {
      value: ethers.utils.parseEther('0.0001'),
    });

    expect(await contract.tokenURI(1)).to.equal('ipfs://placeholder/hidden.json');

    await contract.connect(owner).setBaseURI('ipfs://gomz/metadata/');
    await contract.connect(owner).setRevealState(true);

    expect(await contract.tokenURI(1)).to.equal('ipfs://gomz/metadata/1.json');
  });

  it('enforces whitelist sale rules and exact whitelist payment', async function () {
    const { contract, alice, bob } = await deployFixture();

    await contract.seedWhitelist([alice.address], true);
    await contract.setSalePhase(1);

    await expect(
      contract.connect(bob).mintWhitelist(1, { value: ethers.utils.parseEther('0.0001') })
    ).to.be.revertedWith('Address is not whitelisted');

    await expect(
      contract.connect(alice).mintWhitelist(1, { value: ethers.utils.parseEther('0.0002') })
    ).to.be.revertedWith('Incorrect ETH amount');

    await contract.connect(alice).mintWhitelist(1, {
      value: ethers.utils.parseEther('0.0001'),
    });

    expect(await contract.totalSupply()).to.equal(1);
  });

  it('enforces public sale max per tx and max per wallet', async function () {
    const { contract, alice } = await deployFixture();

    await contract.setSalePhase(2);

    await expect(
      contract.connect(alice).mintPublic(4, { value: ethers.utils.parseEther('0.0008') })
    ).to.be.revertedWith('Max per transaction exceeded');

    await contract.connect(alice).mintPublic(3, {
      value: ethers.utils.parseEther('0.0006'),
    });

    await expect(
      contract.connect(alice).mintPublic(3, { value: ethers.utils.parseEther('0.0006') })
    ).to.be.revertedWith('Max per wallet exceeded');
  });

  it('allows owner reserve minting and withdrawal', async function () {
    const { contract, owner, treasury } = await deployFixture();

    await contract.ownerMint(owner.address, 2);
    expect(await contract.totalSupply()).to.equal(2);

    await contract.setSalePhase(2);
    await contract.mintPublic(1, { value: ethers.utils.parseEther('0.0002') });

    const before = await ethers.provider.getBalance(treasury.address);
    const tx = await contract.withdraw(treasury.address);
    const receipt = await tx.wait();
    const gasCost = receipt.gasUsed.mul(receipt.effectiveGasPrice);

    const after = await ethers.provider.getBalance(treasury.address);
    expect(after.sub(before)).to.equal(ethers.utils.parseEther('0.0002'));
    expect(await ethers.provider.getBalance(contract.address)).to.equal(0);
    expect(gasCost.gt(0)).to.equal(true);
  });
});
