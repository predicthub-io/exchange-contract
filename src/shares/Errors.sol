// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    //0x66f8620a: InvalidComplement()
    //0x3f6cc768: InvalidTokenId()
    //0xdf4d8080: TooLittleTokensReceived()
    //0xe2cc6ad6: MakingGtRemaining()
    //0x5211a079: NotTaker()
    //0xa0b94465: MismatchedTokenIds()
    //0x7f9a6f46: NotCrossing()
    //0xdf4d8080: TooLittleTokensReceived()
    //0x756688fe: InvalidNonce()
    //0x7b38b76e: OrderFilledOrCancelled()
    //0xcd4e6167: FeeTooHigh()
    //0xc56873ba: OrderExpired()
    //0x7b38b76e: OrderFilledOrCancelled()
    //0x30cd7471: NotOwner()
    //0x3a81d6fc: AlreadyRegistered()
    //0x7c214f04: NotOperator()
    //0x7bfa4b9f: NotAdmin()
    //0x5fc483c5: OnlyOwner()
    //0x7d7b71b5: OnlyAuthorized()
    //0x8baa579f: InvalidSignature()
    /*//////////////////////////////////////////////////////////////
                               Tokens
    //////////////////////////////////////////////////////////////*/
    error TransferCollateralFail(); //0x88036b5e

    /*//////////////////////////////////////////////////////////////
                               Adapter
    //////////////////////////////////////////////////////////////*/
    error InvalidIndexSet(); //0x9667d381
    error PartitionNotDisjoint(); //0x01b0248f

    error InvalidPartition(); //0x362f9ddc
    error MarketNotExist(); //0xec5b469b
    error MarketNotResolved(); //0x2e96c726
    error NotAuthorized(); //0xea8e4eb5
    error InvalidAssertedOutcome(); //0x15966f6e
    error ActivedOrResolved(); //0x6bee432d
    error InvalidOutCome(); //0x5c4d4b0a
    error InvalidDesc(); //0x256f02db
    error MarketExisted(); //0x84b157d5
    error UnsupportedCurrency(); //0x2263f4e2
    error NotOwner(); //0x30cd7471
    error PermissionDenied(); //0x1e092104
}
