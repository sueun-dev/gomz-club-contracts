const hre = require('hardhat');

async function main() {
  const placeholderURI = process.env.PLACEHOLDER_URI || 'https://gomz.club/metadata/hidden.json';

  const GomzClubCollection = await hre.ethers.getContractFactory('GomzClubCollection');
  const contract = await GomzClubCollection.deploy(placeholderURI);

  await contract.deployed();

  console.log('GomzClubCollection deployed to:', contract.address);
  console.log('Placeholder URI:', placeholderURI);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
