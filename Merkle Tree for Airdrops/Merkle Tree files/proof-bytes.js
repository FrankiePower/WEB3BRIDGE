const { ethers } = require("ethers");

const proof = [
  "0x8ab4c9c0e2670d1435b89f7e25ade7fb79ed42bd5c2050606caff836d3b9253f",
  "0x221725a524fdf440e34bd68ca561858f14b98631188e58bab12ea25e1cdccc86",
  "0xb8daf07f1beea64b471cabf0dcb45109d1f60b1ce1707b062e0a5de471d510e0",
  "0x9d3cd88071c484513618740bb4cf6cb819557ee7eb0839e52fba1d8c4558136c",
];

function convertProofToBytes32(proof) {
  let result = ethers.constants.HashZero; // Start with zero hash

  for (const element of proof) {
    // Ensure the element is a valid hex string
    if (!ethers.utils.isHexString(element, 32)) {
      throw new Error(`Invalid proof element: ${element}`);
    }

    // Concatenate the current result with the proof element
    const concatenated = ethers.utils.solidityPack(
      ["bytes32", "bytes32"],
      [result, element]
    );

    // Hash the concatenated value
    result = ethers.utils.keccak256(concatenated);
  }

  return result;
}

// Example usage

try {
  const convertedProof = convertProofToBytes32(proof);
  console.log("Converted proof:", convertedProof);
} catch (error) {
  console.error("Error:", error.message);
}
