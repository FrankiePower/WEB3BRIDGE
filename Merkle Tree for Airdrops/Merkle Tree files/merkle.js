const fs = require("fs");
const csv = require("csv-parser");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const csvFilePath = "WhiteList/WhiteList.csv"; // Path to your CSV file

// Function to parse CSV file and create an array of values
const parseCSV = (filePath) => {
  return new Promise((resolve, reject) => {
    const values = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on("data", (row) => {
        // Assuming CSV columns are 'address' and 'amount'
        values.push([row.address, row.amount]);
      })
      .on("end", () => {
        resolve(values);
      })
      .on("error", (error) => {
        reject(error);
      });
  });
};

// Main function to create the Merkle tree
const createMerkleTree = async () => {
  try {
    const values = await parseCSV(csvFilePath);
    const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

    console.log("Merkle Root:", tree.root);

    fs.writeFileSync("tree.json", JSON.stringify(tree.dump(), null, 2));
  } catch (error) {
    console.error("Error creating Merkle tree:", error);
  }
};

// Run the main function
createMerkleTree();
