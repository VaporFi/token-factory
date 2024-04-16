import { deployDiamond } from "./diamond";

async function main() {
  await deployDiamond();
}

main()
  .then(() => {
    console.log("Deployment complete");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
