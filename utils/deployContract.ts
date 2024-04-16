import * as fs from "node:fs";
import * as process from "node:process";
import { artifacts, network, ethers } from "hardhat";
import { type Artifact } from "hardhat/types";
import { saveDeployment } from "./saveDeployment";
import { addresses } from "../config";

export type DeployOptions = {
  args?: any[];
  log?: boolean;
  skipIfAlreadyDeployed?: boolean;
  useCreate3Factory?: boolean;
  salt?: string;
};

export const defaultDeployOptions: DeployOptions = {
  args: [],
  log: true,
  skipIfAlreadyDeployed: process.env.FORCE_DEPLOY === undefined,
  useCreate3Factory: false,
  salt: "",
};

export async function deployContract(
  contractName: string,
  options: DeployOptions = defaultDeployOptions
) {
  const deploymentOptions = {
    ...defaultDeployOptions,
    ...options,
  };

  const networkName = network.name;
  const artifact = await artifacts.readArtifact(contractName);

  console.log("deployContract", {
    contractName,
    deploymentOptions,
    networkName: network.name,
  });

  if (deploymentOptions.skipIfAlreadyDeployed) {
    // Load previous deployment if exists
    const previousDeployment = await loadPreviousDeployment(
      contractName,
      artifact
    );

    if (previousDeployment) {
      console.log(
        `Contract ${contractName} already deployed at ${await previousDeployment.getAddress()}`
      );
      return previousDeployment;
    }
  }
  const Contract = await ethers.getContractFactory(contractName);

  let contract;
  let contractAddress = "";
  if (deploymentOptions.useCreate3Factory) {
    // @ts-expect-error
    if (addresses.create3Factory[networkName] === undefined) {
      throw new Error(
        `CREATE3Factory address not defined for network ${networkName}`
      );
    }

    if (!deploymentOptions.salt) {
      throw new Error("Must provide salt if using CREATE3Factory");
    }

    const CREATE3Factory = await ethers.getContractAt(
      "CREATE3Factory",
      // @ts-expect-error
      addresses.create3Factory[networkName]
    );
    const salt = deploymentOptions.salt;
    const creationCode = ethers.solidityPacked(
      ["bytes", "bytes"],
      [
        Contract.bytecode,
        Contract.interface.encodeDeploy(deploymentOptions.args ?? []),
      ]
    );
    await CREATE3Factory.deploy(salt, creationCode);
    const [deployer] = await ethers.getSigners();
    const addressGenerated = await CREATE3Factory.getDeployed.staticCallResult(
      deployer.address,
      salt
    );
    contractAddress = addressGenerated[0];
    contract = await ethers.getContractAt(contractName, contractAddress);
  } else {
    console.log("Deploying", contractName, "with args", deploymentOptions.args);
    contract = await ethers.deployContract(
      contractName,
      deploymentOptions.args ? deploymentOptions.args : []
    );
    console.log("Waiting for deployment");
    await contract.waitForDeployment();
    console.log("Deployment complete");
    contractAddress = await contract.getAddress();
  }

  saveDeployment(
    contractName,
    { artifact, options: deploymentOptions, address: contractAddress },
    networkName
  );

  if (deploymentOptions.log) {
    console.log(`${contractName} deployed to:`, contractAddress);
  }

  return contract;
}

async function loadPreviousDeployment(
  contractName: string,
  artifact: Artifact
) {
  const networkName = network.name;
  const dirName = "deployments";
  const dirPath = `${process.cwd()}/${dirName}`;
  const filePath = `${dirPath}/${contractName}.json`;

  if (!fs.existsSync(filePath)) {
    return null;
  }

  const previousDeployment = JSON.parse(
    fs.readFileSync(filePath, { encoding: "utf-8" })
  );

  if (previousDeployment[networkName] === undefined) {
    console.log(
      `Contract ${contractName} not deployed on network ${networkName}`
    );
    return null;
  }

  // If contract is already deployed, return it
  if (previousDeployment[networkName].artifact.bytecode === artifact.bytecode) {
    console.log("Contract's bytecode is the same, reusing previous deployment");
    const contract = await ethers.getContractAt(
      contractName,
      previousDeployment[networkName].address
    );

    console.log(
      `Contract ${contractName} already deployed at ${await contract.getAddress()}`
    );

    return contract;
  }

  return null;
}
