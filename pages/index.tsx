import React from "react";
import { useState } from "react";
import Image from "next/image";
import { parseEther } from "viem";
import {
  type BaseError,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import abi from "../abi";
export default function Home() {
  const { data: hash, error, writeContract } = useWriteContract();

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);

    const amount = formData.get("amount") as string;
    if (amount !== null) {
      writeContract({
        address: "0xd42706Da91Ef603d6bA6713F24e6D50c5FE11437",
        abi,
        functionName: "stake",
        args: [1],
        value: parseEther(amount),
      });
    } else {
      console.error("error");
    }
    const { isLoading: isConfirming, isSuccess: isConfirmed } =
      useWaitForTransactionReceipt({
        hash,
      });
  }
  return (
    <div className="bg-black text-white min-h-screen">
      <main className="p-4 flex flex-col mx-64  space-y-3">
        <div className="mt-10 flex flex-row justify-between">
          <h1 className="  py-2 text-4xl ">Staking</h1>

          <w3m-button />
        </div>

        <div className="text-2xl font-bold">Pool Size </div>
        <div>Some demo text abcd</div>
        <div className="flex flex-row bg-foreground rounded-xl  py-6 space-x-8 justify-between ">
          <div className="outline-double flex flex-col p-4  rounded-lg outline-gray-600">
            <div className="flex flex-row justify-around space-x-16 ">
              <div className="text-xl whitespace-nowrap">20 days</div>
              <div className="mt-1 text-gray-400 whitespace-nowrap">
                10% Reward Share
              </div>
            </div>

            <form onSubmit={submit} className="mt-6 flex flex-row">
              <input
                name="amount"
                placeholder="69420"
                required
                className="rounded-lg p-1 bg-gray-800"
              />
              <button type="submit" className="bg-blue-900 rounded-xl ml-5 p-2">
                Stake
              </button>
            </form>
          </div>
          <div className="outline-double flex flex-col p-4 rounded-lg outline-gray-600">
            <div className="flex flex-row justify-around space-x-20">
              <div className="text-xl whitespace-nowrap">40 days</div>
              <div className="mt-1 text-gray-400 whitespace-nowrap">
                15% Reward Share
              </div>
            </div>
            <form className="mt-6 flex flex-row">
              <input
                name="amount"
                placeholder="69420"
                required
                className="rounded-lg p-1 bg-gray-800"
              />
              <button type="submit" className="bg-blue-900 rounded-xl ml-5 p-2">
                Stake
              </button>
            </form>
          </div>
          <div className="outline-double flex flex-col p-4 rounded-lg outline-gray-600">
            <div className="flex flex-row justify-around space-x-20">
              <div className="text-xl whitespace-nowrap">60 days</div>
              <div className="mt-1 text-gray-400 whitespace-nowrap">
                20% Reward Share
              </div>
            </div>
            <form className="mt-6 flex flex-row">
              <input
                name="amount"
                placeholder="69420"
                required
                className="rounded-lg p-1 bg-gray-800"
              />
              <button type="submit" className="bg-blue-900 rounded-xl ml-5 p-2">
                Stake
              </button>
            </form>
          </div>
        </div>
        <h1 className="flex flex-col p-4 rounded-lg bg-foreground ">
          My Stakes
        </h1>
      </main>
    </div>
  );
}
