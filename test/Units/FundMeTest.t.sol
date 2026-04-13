// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {
   FundMe fundMe;

   address user = makeAddr("user");
   uint256 constant SEND_VALUE = 1e18;
   uint256 constant STARTING_BALANCE = 10 ether;
   uint256 constant GAS_PRICE = 1;

   function setUp() external {
       //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
       vm.deal(user, STARTING_BALANCE);
   }

   function testMinimumDollarIsFive() public {
       assertEq(fundMe.MINIMUM_USD(), 5e18);
   }
   
   function testOwnerIsMsgSender() public {
       assertEq(fundMe.getOwner(), msg.sender);
   }
   
   function testPriceFeedVersionIsAccurate() public {
       uint256 version = fundMe.getVersion();
       assertEq(version, 4);
   }
   function testFundFailsWithoutEnoughETH() public {
       vm.expectRevert(); //Hey, the line should revert! //or assret(This tx fails/revert)      
       fundMe.fund();//send 0 eth
   }
   function testFundUpdatesFundedDataStructure() public {
       vm.prank(user); //pretend to be user
       fundMe.fund{value: SEND_VALUE}(); //send 1 eth

       uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
       assertEq(amountFunded, SEND_VALUE);
   }
   function testAddsFunderToArrayOfFunders() public {
       vm.prank(user); //pretend to be user
       fundMe.fund{value: SEND_VALUE}(); //send 1 eth

       address funder = fundMe.getFunder(0);
       assertEq(funder, user);
    }
    modifier funded() {
        vm.prank(user); //pretend to be user
        fundMe.fund{value: SEND_VALUE}(); //send 1 eth
        _;
    }
    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user); //pretend to be user
        vm.expectRevert(); //Hey, the line should revert! //or assret(This tx fails/revert)      
        fundMe.withdraw();
    }
    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = gasStart - gasEnd;
        // uint256 gasCost = gasUsed * GAS_PRICE;  
        // console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    function testWithdrawFromMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(address(i)); //pretend to be user
            // vm.deal(address(i), SEND_VALUE);
            // address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    function testWithdrawFromMultipleFundersCheaper() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(address(i)); //pretend to be user
            // vm.deal(address(i), SEND_VALUE);
            // address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    
}