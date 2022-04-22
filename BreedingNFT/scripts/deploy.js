const { ethers } = require("hardhat");

async function main() {
    const BreedingNFT = await ethers.getContractFactory("BreedingNFT");

    const breedingNFT = await BreedingNFT.deploy();
    await breedingNFT.deployed();

    console.log('[Contract deployed to address:]', breedingNFT.address);
}

main().then(() => process.exit(0))
    .catch(err => {
        console.log('[deploy err]', err);
        process.exit(1);
    })