// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module v2Did = {
  public type AccountIdentifier = Text;
  public type AccountIdentifier__1 = Text;
  public type AssetHandle = Text;
  public type AssetId = Nat32;
  public type AssetType = {
    #other : Text;
    #canister : { id : AssetId; canister : Text };
    #direct : [ChunkId];
  };
  public type Balance = Nat;
  public type BalanceRequest = { token : TokenIdentifier; user : User };
  public type BalanceResponse = { #ok : Balance; #err : CommonError__1 };
  public type Balance__1 = Nat;
  public type ChunkId = Nat32;
  public type CommonError = { #InvalidToken : TokenIdentifier; #Other : Text };
  public type CommonError__1 = {
    #InvalidToken : TokenIdentifier;
    #Other : Text;
  };
  public type Extension = Text;
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    streaming_strategy : ?HttpStreamingStrategy;
    status_code : Nat16;
  };
  public type HttpStreamingCallbackResponse = {
    token : ?HttpStreamingCallbackToken;
    body : [Nat8];
  };
  public type HttpStreamingCallbackToken = {
    key : Text;
    sha256 : ?[Nat8];
    index : Nat;
    content_encoding : Text;
  };
  public type HttpStreamingStrategy = {
    #Callback : {
      token : HttpStreamingCallbackToken;
      callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    };
  };
  public type ListRequest = {
    token : TokenIdentifier__1;
    from_subaccount : ?SubAccount__1;
    price : ?Nat64;
  };
  public type Listing = { locked : ?Time; seller : Principal; price : Nat64 };
  public type Memo = [Nat8];
  public type Metadata = {
    #fungible : {
      decimals : Nat8;
      metadata : ?MetadataContainer;
      name : Text;
      symbol : Text;
    };
    #nonfungible : {
      thumbnail : Text;
      asset : Text;
      metadata : ?MetadataContainer;
      name : Text;
    };
  };
  public type MetadataContainer = {
    #blob : [Nat8];
    #data : [MetadataValue];
    #json : Text;
  };
  public type MetadataLegacy = {
    #fungible : {
      decimals : Nat8;
      metadata : ?[Nat8];
      name : Text;
      symbol : Text;
    };
    #nonfungible : { metadata : ?[Nat8] };
  };
  public type MetadataValue = (
    Text,
    { #nat : Nat; #blob : [Nat8]; #nat8 : Nat8; #text : Text },
  );
  public type Payment = {
    expires : Time;
    subaccount : SubAccount__1;
    payer : AccountIdentifier__1;
    amount : Nat64;
    purchase : PaymentType;
  };
  public type PaymentType = {
    #nft : TokenIndex;
    #nfts : [TokenIndex];
    #sale : Nat64;
  };
  public type Result = {
    #ok : [(TokenIndex, ?Listing, ?[Nat8])];
    #err : CommonError;
  };
  public type Result_1 = { #ok : [TokenIndex]; #err : CommonError };
  public type Result_10 = {
    #ok : (AccountIdentifier__1, ?Listing);
    #err : CommonError;
  };
  public type Result_2 = { #ok : Balance__1; #err : CommonError };
  public type Result_3 = { #ok; #err : CommonError };
  public type Result_4 = { #ok; #err : Text };
  public type Result_5 = { #ok : (AccountIdentifier__1, Nat64); #err : Text };
  public type Result_6 = { #ok : MetadataLegacy; #err : CommonError };
  public type Result_7 = { #ok : AccountIdentifier__1; #err : CommonError };
  public type Result_8 = { #ok : Metadata; #err : CommonError };
  public type Result_9 = {
    #ok : (AccountIdentifier__1, Nat64);
    #err : CommonError;
  };
  public type Sale = {
    end : Time;
    groups : [SalePricingGroup];
    start : Time;
    quantity : Nat;
    remaining : SaleRemaining;
  };
  public type SaleDetailGroup = {
    id : Nat;
    end : Time;
    name : Text;
    available : Bool;
    pricing : [(Nat64, Nat64)];
    start : Time;
  };
  public type SaleDetails = {
    end : Time;
    groups : [SaleDetailGroup];
    start : Time;
    quantity : Nat;
    remaining : Nat;
  };
  public type SalePricingGroup = {
    end : Time;
    participants : [AccountIdentifier__1];
    name : Text;
    limit : (Nat64, Nat64);
    pricing : [(Nat64, Nat64)];
    start : Time;
  };
  public type SaleRemaining = { #retain; #burn; #send : AccountIdentifier__1 };
  public type SaleSettings = {
    startTime : Time;
    whitelist : Bool;
    totalToSell : Nat;
    sold : Nat;
    bulkPricing : [(Nat64, Nat64)];
    whitelistTime : Time;
    salePrice : Nat64;
    remaining : Nat;
    price : Nat64;
  };
  public type SaleTransaction = {
    time : Time;
    seller : Principal;
    tokens : [TokenIndex];
    buyer : AccountIdentifier__1;
    price : Nat64;
  };
  public type SubAccount = [Nat8];
  public type SubAccount__1 = [Nat8];
  public type Time = Int;
  public type TokenIdentifier = Text;
  public type TokenIdentifier__1 = Text;
  public type TokenIndex = Nat32;
  public type Transaction = {
    token : TokenIndex;
    time : Time;
    seller : AccountIdentifier__1;
    buyer : AccountIdentifier__1;
    price : Nat64;
  };
  public type TransferRequest = {
    to : User;
    token : TokenIdentifier;
    notify : Bool;
    from : User;
    memo : Memo;
    subaccount : ?SubAccount;
    amount : Balance;
  };
  public type TransferResponse = {
    #ok : Balance;
    #err : {
      #CannotNotify : AccountIdentifier;
      #InsufficientBalance;
      #InvalidToken : TokenIdentifier;
      #Rejected;
      #Unauthorized : AccountIdentifier;
      #Other : Text;
    };
  };
  public type User = { #principal : Principal; #address : AccountIdentifier };
  public type v2Actor = actor {
    acceptCycles : shared () -> async ();
    addAsset : shared (AssetHandle, Nat32, Text, Text, Text) -> async ();
    addThumbnail : shared (AssetHandle, [Nat8]) -> async ();
    adminKillHeartbeat : shared () -> async ();
    adminStartHeartbeat : shared () -> async ();
    allSettlements : shared query () -> async [
        (
          TokenIndex,
          {
            subaccount : SubAccount__1;
            seller : Principal;
            buyer : AccountIdentifier__1;
            price : Nat64;
          },
        )
      ];
    availableCycles : shared query () -> async Nat;
    balance : shared query BalanceRequest -> async BalanceResponse;
    bearer : shared query TokenIdentifier__1 -> async Result_7;
    details : shared query TokenIdentifier__1 -> async Result_10;
    ext_addAssetCanister : shared () -> async ();
    ext_admin : shared query () -> async Principal;
    ext_assetAdd : shared (AssetHandle, Text, Text, AssetType, Nat) -> async ();
    ext_assetExists : shared query AssetHandle -> async Bool;
    ext_assetFits : shared query (Bool, Nat) -> async Bool;
    ext_assetStream : shared (AssetHandle, [Nat8], Bool) -> async Bool;
    ext_balance : shared query BalanceRequest -> async BalanceResponse;
    ext_bearer : shared query TokenIdentifier__1 -> async Result_7;
    ext_capInit : shared () -> async ();
    ext_expired : shared query () -> async [
        (AccountIdentifier__1, SubAccount__1)
      ];
    ext_extensions : shared query () -> async [Extension];
    ext_marketplaceList : shared ListRequest -> async Result_3;
    ext_marketplaceListings : shared query () -> async [
        (TokenIndex, Listing, Metadata)
      ];
    ext_marketplacePurchase : shared (
        TokenIdentifier__1,
        Nat64,
        AccountIdentifier__1,
      ) -> async Result_9;
    ext_marketplaceSettle : shared AccountIdentifier__1 -> async Result_3;
    ext_marketplaceStats : shared query () -> async (
        Nat64,
        Nat64,
        Nat64,
        Nat64,
        Nat,
        Nat,
        Nat,
      );
    ext_marketplaceTransactions : shared query () -> async [Transaction];
    ext_metadata : shared query TokenIdentifier__1 -> async Result_8;
    ext_mint : shared [(AccountIdentifier__1, Metadata)] -> async [TokenIndex];
    ext_payments : shared query () -> async [(AccountIdentifier__1, Payment)];
    ext_removeAdmin : shared () -> async ();
    ext_saleClose : shared () -> async Bool;
    ext_saleCurrent : shared query () -> async ?Sale;
    ext_saleOpen : shared (
        [SalePricingGroup],
        SaleRemaining,
        [AccountIdentifier__1],
      ) -> async Bool;
    ext_salePurchase : shared (
        Nat,
        Nat64,
        Nat64,
        AccountIdentifier__1,
      ) -> async Result_5;
    ext_saleSettings : shared query AccountIdentifier__1 -> async ?SaleDetails;
    ext_saleSettle : shared AccountIdentifier__1 -> async Result_4;
    ext_saleTransactions : shared query () -> async [SaleTransaction];
    ext_saleUpdate : shared (
        ?[SalePricingGroup],
        ?SaleRemaining,
        ?[AccountIdentifier__1],
      ) -> async Bool;
    ext_setAdmin : shared Principal -> async ();
    ext_setCollectionMetadata : shared (Text, Text) -> async ();
    ext_setMarketplaceOpen : shared Time -> async ();
    ext_setOwner : shared Principal -> async ();
    ext_setRoyalty : shared (AccountIdentifier__1, Nat64) -> async ();
    ext_transfer : shared TransferRequest -> async TransferResponse;
    extdata_supply : shared query TokenIdentifier__1 -> async Result_2;
    extensions : shared query () -> async [Extension];
    failedSales : shared query () -> async [
        (AccountIdentifier__1, SubAccount__1)
      ];
    getMetadata : shared query () -> async [(TokenIndex, MetadataLegacy)];
    getMinter : shared query () -> async Principal;
    getRegistry : shared query () -> async [(TokenIndex, AccountIdentifier__1)];
    getTokens : shared query () -> async [(TokenIndex, MetadataLegacy)];
    heartbeat_assetCanisters : shared () -> async ();
    heartbeat_capEvents : shared () -> async ();
    heartbeat_disbursements : shared () -> async ();
    heartbeat_external : shared () -> async ();
    heartbeat_isRunning : shared query () -> async Bool;
    heartbeat_paymentSettlements : shared () -> async ();
    heartbeat_pending : shared query () -> async [(Text, Nat)];
    heartbeat_start : shared () -> async ();
    heartbeat_stop : shared () -> async ();
    http_request : shared query HttpRequest -> async HttpResponse;
    http_request_streaming_callback : shared query HttpStreamingCallbackToken -> async HttpStreamingCallbackResponse;
    isHeartbeatRunning : shared query () -> async Bool;
    list : shared ListRequest -> async Result_3;
    listings : shared query () -> async [(TokenIndex, Listing, MetadataLegacy)];
    lock : shared (
        TokenIdentifier__1,
        Nat64,
        AccountIdentifier__1,
        SubAccount__1,
      ) -> async Result_7;
    metadata : shared query TokenIdentifier__1 -> async Result_6;
    reserve : shared (
        Nat64,
        Nat64,
        AccountIdentifier__1,
        SubAccount__1,
      ) -> async Result_5;
    retreive : shared AccountIdentifier__1 -> async Result_4;
    saleTransactions : shared query () -> async [SaleTransaction];
    salesSettings : shared query AccountIdentifier__1 -> async SaleSettings;
    setMinter : shared Principal -> async ();
    settle : shared TokenIdentifier__1 -> async Result_3;
    settlements : shared query () -> async [
        (TokenIndex, AccountIdentifier__1, Nat64)
      ];
    stats : shared query () -> async (
        Nat64,
        Nat64,
        Nat64,
        Nat64,
        Nat,
        Nat,
        Nat,
      );
    supply : shared query TokenIdentifier__1 -> async Result_2;
    tokens : shared query AccountIdentifier__1 -> async Result_1;
    tokens_ext : shared query AccountIdentifier__1 -> async Result;
    transactions : shared query () -> async [Transaction];
    transfer : shared TransferRequest -> async TransferResponse;
  }
}