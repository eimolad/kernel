import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Char "mo:base/Char";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Option "mo:base/Option";

import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import ExtCommon "../motoko/ext/Common";
import ExtAllowance "../motoko/ext/Allowance";
import ExtNonFungible "../motoko/ext/NonFungible";
//EXTv2 SALE
import Int64 "mo:base/Int64";
import List "mo:base/List";
import Encoding "mo:encoding/Binary";
//Cap
import Cap "mo:cap/Cap";
actor class EimoladKernel() = this {
  
  // Types
  type Time = Time.Time;
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type TokenIndex  = ExtCore.TokenIndex ;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type AllowanceRequest = ExtAllowance.AllowanceRequest;
  type ApproveRequest = ExtAllowance.ApproveRequest;
  type Metadata = ExtCommon.Metadata;
  type NotifyService = ExtCore.NotifyService;
  type MintingRequest = {
    to : AccountIdentifier;
    asset : Nat32;
  };
  
  //Marketplace
  type Transaction = {
    token : TokenIdentifier;
    seller : Principal;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
  type Settlement = {
    seller : Principal;
    price : Nat64;
    subaccount : SubAccount;
    buyer : AccountIdentifier;
  };
  type Listing = {
    seller : Principal;
    price : Nat64;
    locked : ?Time;
  };
  type ListRequest = {
    token : TokenIdentifier;
    from_subaccount : ?SubAccount;
    price : ?Nat64;
  };
  type AccountBalanceArgs = { account : AccountIdentifier };
  type ICPTs = { e8s : Nat64 };

  type SendArgs = {
    memo: Nat64;
    amount: ICPTs;
    fee: ICPTs;
    from_subaccount: ?SubAccount;
    to: AccountIdentifier;
    created_at_time: ?Time;
  };
  let LEDGER_CANISTER = actor "ryjl3-tyaaa-aaaaa-aaaba-cai" : actor { 
    send_dfx : shared SendArgs -> async Nat64;
    account_balance_dfx : shared query AccountBalanceArgs -> async ICPTs; 
  };
  
  //Cap
  type CapDetailValue = {
    #I64 : Int64;
    #U64 : Nat64;
    #Vec : [CapDetailValue];
    #Slice : [Nat8];
    #Text : Text;
    #True;
    #False;
    #Float : Float;
    #Principal : Principal;
  };
  type CapEvent = {
    time : Nat64;
    operation : Text;
    details : [(Text, CapDetailValue)];
    caller : Principal;
  };
  type CapIndefiniteEvent = {
    operation : Text;
    details : [(Text, CapDetailValue)];
    caller : Principal;
  };
  //EXTv2 SALE
  private stable var _disbursementsState : [(TokenIndex, AccountIdentifier, SubAccount, Nat64)] = [];
  private stable var _nextSubAccount : Nat = 0;
  private var _disbursements : List.List<(TokenIndex, AccountIdentifier, SubAccount, Nat64)> = List.fromArray(_disbursementsState);
  private var salesFees : [(AccountIdentifier, Nat64)] = [
    ("338cc64c631e2aadfc3975f81c102339d3f91b5a40c7124f03602299a2bab0ad", 2500), //Royalty Fee 2,5% iBardak  (Eimolad change)
    ("c7e461041c0c5800a56b64bb7cefc247abc0bbbb99bd46ff71c64e92d9f5c2f9", 1000), //Entrepot Fee 1%
  ];
  
  //CAP
  private stable var capRootBucketId : ?Text = null;
  let CapService = Cap.Cap(?"lj532-6iaaa-aaaah-qcc7a-cai", capRootBucketId);
  private stable var _capEventsState : [CapIndefiniteEvent] = [];
  private var _capEvents : List.List<CapIndefiniteEvent> = List.fromArray(_capEventsState);
  private stable var _runHeartbeat : Bool = true;
  
  type AssetHandle = Text;
  type Asset = {
    id : Nat32;
    ctype : Text;
    name : Text;
    canister : Text;
  };
  
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/nonfungible"];
  
  //State work
  private stable var _registryState : [(TokenIndex, AccountIdentifier)] = [];
	private stable var _tokenMetadataState : [(TokenIndex, Metadata)] = [];
  private stable var _ownersState : [(AccountIdentifier, [TokenIndex])] = [];
  
  //For marketplace
	private stable var _tokenListingState : [(TokenIndex, Listing)] = [];
	private stable var _tokenSettlementState : [(TokenIndex, Settlement)] = [];
	private stable var _paymentsState : [(Principal, [SubAccount])] = [];
	private stable var _refundsState : [(Principal, [SubAccount])] = [];
	private stable var _assetsState : [(AssetHandle, Asset)] = [];
	private stable var _tokenAssetsState : [(TokenIndex, AssetHandle)] = [];
	private stable var _assetThumbState : [(AssetHandle, Blob)] = [];
	private stable var _tokenAssetsReverseState : [(AssetHandle, TokenIndex)] = [];
  
  private var _registry : HashMap.HashMap<TokenIndex, AccountIdentifier> = HashMap.fromIter(_registryState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _tokenMetadata : HashMap.HashMap<TokenIndex, Metadata> = HashMap.fromIter(_tokenMetadataState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
	private var _owners : HashMap.HashMap<AccountIdentifier, [TokenIndex]> = HashMap.fromIter(_ownersState.vals(), 0, AID.equal, AID.hash);
	private var _assets : HashMap.HashMap<AssetHandle, Asset> = HashMap.fromIter(_assetsState.vals(), 0, AID.equal, AID.hash);
	private var _tokenAssets : HashMap.HashMap<TokenIndex, AssetHandle> = HashMap.fromIter(_tokenAssetsState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _assetThumb : HashMap.HashMap<AssetHandle, Blob> = HashMap.fromIter(_assetThumbState.vals(), 0, AID.equal, AID.hash);
	private var _tokenAssetsReverse : HashMap.HashMap<AssetHandle, TokenIndex> = HashMap.fromIter(_tokenAssetsReverseState.vals(), 0, AID.equal, AID.hash);
  
  //For marketplace
  private var _tokenListing : HashMap.HashMap<TokenIndex, Listing> = HashMap.fromIter(_tokenListingState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _tokenSettlement : HashMap.HashMap<TokenIndex, Settlement> = HashMap.fromIter(_tokenSettlementState.vals(), 0, ExtCore.TokenIndex.equal, ExtCore.TokenIndex.hash);
  private var _payments : HashMap.HashMap<Principal, [SubAccount]> = HashMap.fromIter(_paymentsState.vals(), 0, Principal.equal, Principal.hash);
  private var _refunds : HashMap.HashMap<Principal, [SubAccount]> = HashMap.fromIter(_refundsState.vals(), 0, Principal.equal, Principal.hash);
  private var ESCROWDELAY : Time = 10* 60 * 1_000_000_000;
	private stable var _usedPaymentAddressess : [(AccountIdentifier, Principal, SubAccount)] = [];
	private stable var _transactions : [Transaction] = [];
  private stable var _supply : Balance  = 0;
  private stable var _minter : Principal  = Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe");
  private stable var _nextTokenId : TokenIndex  = 0;
  //_assets := [];

  //State functions
  system func preupgrade() {
    _registryState := Iter.toArray(_registry.entries());
    _tokenMetadataState := Iter.toArray(_tokenMetadata.entries());
    _ownersState := Iter.toArray(_owners.entries());
    _tokenListingState := Iter.toArray(_tokenListing.entries());
    _tokenSettlementState := Iter.toArray(_tokenSettlement.entries());
    _paymentsState := Iter.toArray(_payments.entries());
    _refundsState := Iter.toArray(_refunds.entries());
    _assetsState := Iter.toArray(_assets.entries());
    _tokenAssetsState := Iter.toArray(_tokenAssets.entries());
    _assetThumbState := Iter.toArray(_assetThumb.entries());
    _tokenAssetsReverseState := Iter.toArray(_tokenAssetsReverse.entries());
    _salesSettlementsState := Iter.toArray(_salesSettlements.entries());
    //EXTv2 SALE
    _disbursementsState := List.toArray(_disbursements);
    
    //Cap
    _capEventsState := List.toArray(_capEvents);
    
  };
  system func postupgrade() {
    _registryState := [];
    _tokenMetadataState := [];
    _ownersState := [];
    _tokenListingState := [];
    _tokenSettlementState := [];
    _paymentsState := [];
    _refundsState := [];
    _assetsState := [];
    _tokenAssetsState := [];
    _assetThumbState := [];
    _tokenAssetsReverseState := [];
    _salesSettlementsState := [];
    //EXTv2 SALE
    _disbursementsState := [];

    //Cap
    _capEventsState := [];
    
  };
  
  //Sale
  type Sale = {
    tokens : [TokenIndex];
    price : Nat64;
    subaccount : SubAccount;
    buyer : AccountIdentifier;
    expires : Time;
  };
  
  type SaleTransaction = {
    tokens : [TokenIndex];
    seller : Principal;
    price : Nat64;
    buyer : AccountIdentifier;
    time : Time;
  };
	private stable var _saleTransactions : [SaleTransaction] = [];
  private stable var _salesSettlementsState : [(AccountIdentifier, Sale)] = [];
  private var _salesSettlements : HashMap.HashMap<AccountIdentifier, Sale> = HashMap.fromIter(_salesSettlementsState.vals(), 0, AID.equal, AID.hash);
  private stable var _failedSales : [(AccountIdentifier, SubAccount)] = [];
  var totalToSell : Nat = 2500; // Do I understand correctly that I am specifying the size of the entire collection here, including the reserved command tokens? (Eimolad change)
  var salePrice : Nat64 = 700000000; //6 ICP. I'll change it later (Eimolad change)
  var whitelistPrice : Nat64 = 500000000; //5 ICP. I'll change it later
  var publicSaleStart : Time = 1648731600000000000; // 3/31/2022 13:00:00 UTC (Eimolad change)
  var whitelistTime : Time = 1648735200000000000; // 3/31/2022 14:00:00 UTC (Eimolad change)
  var whitelistOneTimeOnly : Bool = true; // Do I understand correctly that this flag is responsible for different times of the whitelist sale and publicsale (Eimolad change)
  //set to 0, 24, 72 or custom
  var marketDelay : Time = 24 * 60 * 60 * 1_000_000_000;
  stable var _soldIcp : Nat64 = 0;
  stable var _whitelist : [AccountIdentifier] = [];
  stable var _sold : Nat = 0;
  stable var _reserved : Nat = 0;
  
  func nextTokens(qty : Nat64) : [TokenIndex] {
    //Custom: not pre-mint
    var ret : [TokenIndex] = [];
    while(ret.size() < Nat64.toNat(qty)) {        
      ret := Array.append(ret, [0:TokenIndex]);
    };
    ret;
  };
  func isWhitelisted(address : AccountIdentifier) : Bool {
    if (Time.now() >= whitelistTime) {
      false;
    } else {
      Option.isSome(Array.find(_whitelist, func (a : AccountIdentifier) : Bool { a == address }));
    };
  };
  func getAddressPrice(address : AccountIdentifier) : Nat64 {
    getAddressBulkPrice(address)[0].1;
  };
  func getAddressBulkPrice(address : AccountIdentifier) : [(Nat64, Nat64)] {
    if (isWhitelisted(address)){
      return [(1, whitelistPrice)] //5 ICP. we have one NFT per wallet. What needs to be changed here? (Eimolad change)
    };
    return [(1, salePrice)] //6 ICP. we have a purchase of one NFT (Eimolad change)   
  };
  func removeFromWhitelist(address : AccountIdentifier) : () {
    _whitelist := Array.filter(_whitelist, func (a : AccountIdentifier) : Bool { a != address });
  };
  func addToWhitelist(address : AccountIdentifier) : () {
    _whitelist := Array.append(_whitelist, [address]);
  };
  public query(msg) func saleTransactions() : async [SaleTransaction] {
    _saleTransactions;
  };
  type SaleSettings = {
    price : Nat64;
    salePrice : Nat64;
    sold : Nat;
    remaining : Nat;
    startTime : Time;
    whitelistTime : Time;
    whitelist : Bool;
    totalToSell : Nat;
    bulkPricing : [(Nat64, Nat64)];
  };
  
  func availableTokens() : Nat {
    //Custom: not pre-mint
    2500-_reserved-_sold : Nat;
  };
  public query(msg) func salesSettings(address : AccountIdentifier) : async SaleSettings {
    return {
      price = getAddressPrice(address);
      salePrice = salePrice;
      remaining = availableTokens();
      sold = _sold;
      startTime = publicSaleStart;
      whitelistTime = whitelistTime;
      whitelist = isWhitelisted(address);
      totalToSell = totalToSell;
      bulkPricing = getAddressBulkPrice(address);
    } : SaleSettings;
  };
  var salesAccount : Principal = Principal.fromText("jdfjg-amcja-wo3zr-6li5k-o4e5f-ymqfk-f4xk2-37o3d-2mezb-45y3t-5qe");
  public shared(msg) func reserve(amount : Nat64, quantity : Nat64, address : AccountIdentifier, subaccount : SubAccount) : async Result.Result<(AccountIdentifier, Nat64), Text> {
    if (Time.now() < publicSaleStart) {
      return #err("The sale has not started yet");
    };
    //Custom: End after 24h
    if (Time.now() >= (publicSaleStart+marketDelay)) {
      return #err("The sale is over!");
    };
    if (isWhitelisted(address) == false) {
      if (Time.now() < whitelistTime) {
        return #err("The public sale has not started yet");
      };            
    };
    if (availableTokens() == 0) {
      return #err("No more NFTs available right now!");
    };
    if (availableTokens() < Nat64.toNat(quantity)) {
      return #err("Quantity error");
    };
    var total : Nat64 = (getAddressPrice(address) * quantity);
    var bp = getAddressBulkPrice(address);
    var lastq : Nat64 = 1;
    for(a in bp.vals()){
      if (a.0 == quantity) {
        total := a.1;
      };
      lastq := a.0;
    };
    if (quantity > lastq){
      return #err("Quantity error");
    };
    if (total > amount) {
      return #err("Price mismatch!");
    };
    let paymentAddress : AccountIdentifier = AID.fromPrincipal(salesAccount, ?subaccount);
    if (Option.isSome(Array.find<(AccountIdentifier, Principal, SubAccount)>(_usedPaymentAddressess, func (a : (AccountIdentifier, Principal, SubAccount)) : Bool { a.0 == paymentAddress}))) {
      return #err("Payment address has been used");
    };

    let tokens : [TokenIndex] = nextTokens(quantity);
    if (tokens.size() == 0) {
      return #err("Not enough NFTs available!");
    };
    if (tokens.size() != Nat64.toNat(quantity)) {
      return #err("Quantity error");
    };
    if (whitelistOneTimeOnly == true){
      if (isWhitelisted(address)) {
        removeFromWhitelist(address);
      };
    };
    //Custom: not pre-mint
    _reserved += Nat64.toNat(quantity);
    _usedPaymentAddressess := Array.append(_usedPaymentAddressess, [(paymentAddress, salesAccount, subaccount)]);
    _salesSettlements.put(paymentAddress, {
      tokens = tokens;
      price = total;
      subaccount = subaccount;
      buyer = address;
      expires = (Time.now() + ESCROWDELAY);
    });
    #ok((paymentAddress, total));
  };
  public shared(msg) func retreive(paymentaddress : AccountIdentifier) : async Result.Result<(), Text> {
    switch(_salesSettlements.get(paymentaddress)) {
      case(?settlement){
        let response : ICPTs = await LEDGER_CANISTER.account_balance_dfx({account = paymentaddress});
        switch(_salesSettlements.get(paymentaddress)) {
          case(?settlement){
            if (response.e8s >= settlement.price){
              _payments.put(salesAccount, switch(_payments.get(salesAccount)) {
                case(?p) Array.append(p, [settlement.subaccount]);
                case(_) [settlement.subaccount];
              });
              //Custom: not pre-mint
              var tokens = _mintNftsIndexedForAddress(settlement.tokens.size(), settlement.buyer);
              _saleTransactions := Array.append(_saleTransactions, [{
                tokens = tokens;
                seller = salesAccount;
                price = settlement.price;
                buyer = settlement.buyer;
                time = Time.now();
              }]);
              _soldIcp += settlement.price;
              _sold += tokens.size();
              //Custom: not pre-mint
              _reserved -= tokens.size();
              _salesSettlements.delete(paymentaddress);
              return #ok();
            } else {
              if (settlement.expires < Time.now()) {
                _failedSales := Array.append(_failedSales, [(settlement.buyer, settlement.subaccount)]);
                _salesSettlements.delete(paymentaddress);
                if (whitelistOneTimeOnly == true){
                  if (settlement.price == whitelistPrice) {
                    addToWhitelist(settlement.buyer);
                  };
                };
                //Custom: not pre-mint
                _reserved -= settlement.tokens.size();
                return #err("Expired");
              } else {
                return #err("Insufficient funds sent");
              }
            };
          };
          case(_) return #err("Nothing to settle");
        };
      };
      case(_) return #err("Nothing to settle");
    };
  };
  
  public query func salesSettlements() : async [(AccountIdentifier, Sale)] {
    Iter.toArray(_salesSettlements.entries());
  };
  public query func failedSales() : async [(AccountIdentifier, SubAccount)] {
    _failedSales;
  };
  //EXTv2 SALE
  system func heartbeat() : async () {
    if (_runHeartbeat == true){
      await cronDisbursements();
      await cronSettlements();
      await cronCapEvents();
    };
  };
  //Listings
  //EXTv2 SALE
  public query func toAddress(p : Text, sa : Nat) : async AccountIdentifier {
    AID.fromPrincipal(Principal.fromText(p), ?_natToSubAccount(sa));
  };
  func _natToSubAccount(n : Nat) : SubAccount {
    let n_byte = func(i : Nat) : Nat8 {
        assert(i < 32);
        let shift : Nat = 8 * (32 - 1 - i);
        Nat8.fromIntWrap(n / 2**shift)
    };
    Array.tabulate<Nat8>(32, n_byte)
  };
  func _getNextSubAccount() : SubAccount {
    var _saOffset = 4294967296;
    _nextSubAccount += 1;
    return _natToSubAccount(_saOffset+_nextSubAccount);
  };
  func _addDisbursement(d : (TokenIndex, AccountIdentifier, SubAccount, Nat64)) : () {
    _disbursements := List.push(d, _disbursements);
  };
  public shared(msg) func lock(tokenid : TokenIdentifier, price : Nat64, address : AccountIdentifier, _subaccountNOTUSED : SubAccount) : async Result.Result<AccountIdentifier, CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(tokenid, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(tokenid));
		};
		let token = ExtCore.TokenIdentifier.getIndex(tokenid);
    if (_isLocked(token)) {					
      return #err(#Other("Listing is locked"));				
    };
    let subaccount = _getNextSubAccount();
		switch(_tokenListing.get(token)) {
			case (?listing) {
        if (listing.price != price) {
          return #err(#Other("Price has changed!"));
        } else {
          let paymentAddress : AccountIdentifier = AID.fromPrincipal(Principal.fromActor(this), ?subaccount);
          _tokenListing.put(token, {
            seller = listing.seller;
            price = listing.price;
            locked = ?(Time.now() + ESCROWDELAY);
          });
          switch(_tokenSettlement.get(token)) {
            case(?settlement){
              let resp : Result.Result<(), CommonError> = await settle(tokenid);
              switch(resp) {
                case(#ok) {
                  return #err(#Other("Listing has sold"));
                };
                case(#err _) {
                  //Atomic protection
                  if (Option.isNull(_tokenListing.get(token))) return #err(#Other("Listing has sold"));
                };
              };
            };
            case(_){};
          };
          _tokenSettlement.put(token, {
            seller = listing.seller;
            price = listing.price;
            subaccount = subaccount;
            buyer = address;
          });
          return #ok(paymentAddress);
        };
			};
			case (_) {
				return #err(#Other("No listing!"));				
			};
		};
  };
  public shared(msg) func settle(tokenid : TokenIdentifier) : async Result.Result<(), CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(tokenid, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(tokenid));
		};
		let token = ExtCore.TokenIdentifier.getIndex(tokenid);
    switch(_tokenSettlement.get(token)) {
      case(?settlement){
        let response : ICPTs = await LEDGER_CANISTER.account_balance_dfx({account = AID.fromPrincipal(Principal.fromActor(this), ?settlement.subaccount)});
        switch(_tokenSettlement.get(token)) {
          case(?settlement){
            if (response.e8s >= settlement.price){
              switch (_registry.get(token)) {
                case (?token_owner) {
                  var bal : Nat64 = settlement.price - (10000 * Nat64.fromNat(salesFees.size() + 1));
                  var rem = bal;
                  for(f in salesFees.vals()){
                    var _fee : Nat64 = bal * f.1 / 100000;
                    _addDisbursement((token, f.0, settlement.subaccount, _fee));
                    rem := rem -  _fee : Nat64;
                  };
                  _addDisbursement((token, token_owner, settlement.subaccount, rem));
                  _capAddSale(token, token_owner, settlement.buyer, settlement.price);
                  _transferTokenToUser(token, settlement.buyer);
                  _transactions := Array.append(_transactions, [{
                    token = tokenid;
                    seller = settlement.seller;
                    price = settlement.price;
                    buyer = settlement.buyer;
                    time = Time.now();
                  }]);
                  _tokenListing.delete(token);
                  _tokenSettlement.delete(token);
                  return #ok();
                };
                case (_) {
                  return #err(#InvalidToken(tokenid));
                };
              };
            } else {
              if (_isLocked(token)) {					
                return #err(#Other("Insufficient funds sent"));
              } else {
                _tokenSettlement.delete(token);
                return #err(#Other("Nothing to settle"));				
              };
            };
          };
          case(_) return #err(#Other("Nothing to settle"));
        };
      };
      case(_) return #err(#Other("Nothing to settle"));
    };
  };
  public shared(msg) func list(request: ListRequest) : async Result.Result<(), CommonError> {
    if (Time.now() < (publicSaleStart+marketDelay)) {
      if (_sold < totalToSell){
        return #err(#Other("You can not list yet"));
      };
    };
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    if (_isLocked(token)) {					
      return #err(#Other("Listing is locked"));				
    };
    switch(_tokenSettlement.get(token)) {
      case(?settlement){
        let resp : Result.Result<(), CommonError> = await settle(request.token);
        switch(resp) {
          case(#ok) return #err(#Other("Listing as sold"));
          case(#err _) {};
        };
      };
      case(_){};
    };
    let owner = AID.fromPrincipal(msg.caller, request.from_subaccount);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if(AID.equal(owner, token_owner) == false) {
					return #err(#Other("Not authorized"));
				};
        switch(request.price) {
          case(?price) {
            _tokenListing.put(token, {
              seller = msg.caller;
              price = price;
              locked = null;
            });
          };
          case(_) {
            _tokenListing.delete(token);
          };
        };
        if (Option.isSome(_tokenSettlement.get(token))) {
          _tokenSettlement.delete(token);
        };
        return #ok;
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
  public shared(msg) func cronDisbursements() : async () {
    var _cont : Bool = true;
    while(_cont){ _cont := false;
      var last = List.pop(_disbursements);
      switch(last.0){
        case(?d) {
          _disbursements := last.1;
          try {
            var bh = await LEDGER_CANISTER.send_dfx({
              //memo = Encoding.BigEndian.toNat64(Blob.toArray(Principal.toBlob(Principal.fromText(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), d.0)))));
              memo = 0;
              amount = { e8s = d.3 };
              fee = { e8s = 10000 };
              from_subaccount = ?d.2;
              to = d.1;
              created_at_time = null;
            });
          } catch (e) {
            _disbursements := List.push(d, _disbursements);
          };
        };
        case(_) {
          _cont := false;
        };
      };
    };
  };
  public shared(msg) func cronSettlements() : async () {
    for(settlement in _tokenSettlement.entries()){
        ignore(settle(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), settlement.0)));
    };
  };
  
  //Cap
  func _capAddTransfer(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier) : () {
    let event : CapIndefiniteEvent = {
      operation = "transfer";
      details = [
        ("to", #Text(to)),
        ("from", #Text(from)),
        ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
        ("balance", #U64(1)),
      ];
      caller = Principal.fromActor(this);
    };
    _capAdd(event);
  };
  func _capAddSale(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier, amount : Nat64) : () {
    let event : CapIndefiniteEvent = {
      operation = "sale";
      details = [
        ("to", #Text(to)),
        ("from", #Text(from)),
        ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
        ("balance", #U64(1)),
        ("price_decimals", #U64(8)),
        ("price_currency", #Text("ICP")),
        ("price", #U64(amount)),
      ];
      caller = Principal.fromActor(this);
    };
    _capAdd(event);
  };
  func _capAddMint(token : TokenIndex, from : AccountIdentifier, to : AccountIdentifier, amount : ?Nat64) : () {
    let event : CapIndefiniteEvent = switch(amount) {
      case(?a) {
        {
          operation = "mint";
          details = [
            ("to", #Text(to)),
            ("from", #Text(from)),
            ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
            ("balance", #U64(1)),
            ("price_decimals", #U64(8)),
            ("price_currency", #Text("ICP")),
            ("price", #U64(a)),
          ];
          caller = Principal.fromActor(this);
        };
      };
      case(_) {
        {
          operation = "mint";
          details = [
            ("to", #Text(to)),
            ("from", #Text(from)),
            ("token", #Text(ExtCore.TokenIdentifier.fromPrincipal(Principal.fromActor(this), token))),
            ("balance", #U64(1)),
          ];
          caller = Principal.fromActor(this);
        };
      };
    };
    _capAdd(event);
  };
  func _capAdd(event : CapIndefiniteEvent) : () {
    _capEvents := List.push(event, _capEvents);
  };
  public shared(msg) func cronCapEvents() : async () {
    var _cont : Bool = true;
    while(_cont){ _cont := false;
      var last = List.pop(_capEvents);
      switch(last.0){
        case(?event) {
          _capEvents := last.1;
          try {
            ignore await CapService.insert(event);
          } catch (e) {
            _capEvents := List.push(event, _capEvents);
          };
        };
        case(_) {
          _cont := false;
        };
      };
    };
  };
  public shared(msg) func initCap() : async () {
    if (Option.isNull(capRootBucketId)){
      try {
        capRootBucketId := await CapService.handshake(Principal.toText(Principal.fromActor(this)), 1_000_000_000_000);
      } catch e {};
    };
  };
  private stable var historicExportHasRun : Bool = false;
  public shared(msg) func historicExport() : async Bool {
    if (historicExportHasRun == false){
      var events : [CapEvent] = [];
      for(tx in _transactions.vals()){
        let event : CapEvent = {
          time = Int64.toNat64(Int64.fromInt(tx.time));
          operation = "sale";
          details = [
            ("to", #Text(tx.buyer)),
            ("from", #Text(Principal.toText(tx.seller))),
            ("token", #Text(tx.token)),
            ("balance", #U64(1)),
            ("price_decimals", #U64(8)),
            ("price_currency", #Text("ICP")),
            ("price", #U64(tx.price)),
          ];
          caller = Principal.fromActor(this);
        };
        events := Array.append(events, [event]);
      };
      try {
        ignore(await CapService.migrate(events));
        historicExportHasRun := true;        
      } catch (e) {};
    };
    historicExportHasRun;
  };
  public shared(msg) func adminKillHeartbeat() : async () {
    assert(msg.caller == _minter);
    _runHeartbeat := false;
  };
  public shared(msg) func adminStartHeartbeat() : async () {
    assert(msg.caller == _minter);
    _runHeartbeat := true;
  };

  	public shared(msg) func setMinter(minter : Principal) : async () {
		assert(msg.caller == _minter);
		_minter := minter;
	};
  public shared(msg) func addThumbnail(handle : AssetHandle, data : Blob) : async () {
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    _assetThumb.put(handle, data);
  };
  public shared(msg) func addAsset(handle : AssetHandle, id : Nat32, ctype : Text, name : Text, canister : Text) : async () {
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    _assets.put(handle, {
      id = id;
      ctype = ctype;
      name = name;
      canister = canister;
    });
  };
  
  public query func assetTokenMap() : async [(AssetHandle, TokenIndex)] {
    Iter.toArray(_tokenAssetsReverse.entries());
  };
  public query func assetsToTokens(assets : [AssetHandle]) : async [TokenIndex] {
    var ret : [TokenIndex] = [];
    for(a in assets.vals()){
      switch(_tokenAssetsReverse.get(a)) {
        case(?b) ret := Array.append(ret, [b]);
        case(_) {};
      };
    };
    ret;
  };
  
  //EXT
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    if (request.amount != 1) {
			return #err(#Other("Must use amount of 1"));
		};
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    if (Option.isSome(_tokenListing.get(token))) {
			return #err(#Other("This token is currently listed for sale!"));
    };
    let owner = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
		if (AID.equal(owner, spender) == false) {
      return #err(#Unauthorized(spender));
    };
    switch (_registry.get(token)) {
      case (?token_owner) {
				if(AID.equal(owner, token_owner) == false) {
					return #err(#Unauthorized(owner));
				};
        if (request.notify) {
          switch(ExtCore.User.toPrincipal(request.to)) {
            case (?canisterId) {
              //Do this to avoid atomicity issue
              _removeTokenFromUser(token);
              let notifier : NotifyService = actor(Principal.toText(canisterId));
              switch(await notifier.tokenTransferNotification(request.token, request.from, request.amount, request.memo)) {
                case (?balance) {
                  if (balance == 1) {
                    _transferTokenToUser(token, receiver);
    _capAddTransfer(token, owner, receiver);
                    return #ok(request.amount);
                  } else {
                    //Refund
                    _transferTokenToUser(token, owner);
                    return #err(#Rejected);
                  };
                };
                case (_) {
                  //Refund
                  _transferTokenToUser(token, owner);
                  return #err(#Rejected);
                };
              };
            };
            case (_) {
              return #err(#CannotNotify(receiver));
            }
          };
        } else {
          _transferTokenToUser(token, receiver);
    _capAddTransfer(token, owner, receiver);
          return #ok(request.amount);
        };
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
  public query func getMinter() : async Principal {
    _minter;
  };
  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  public query func balance(request : BalanceRequest) : async BalanceResponse {
		if (ExtCore.TokenIdentifier.isPrincipal(request.token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(request.token));
		};
		let token = ExtCore.TokenIdentifier.getIndex(request.token);
    let aid = ExtCore.User.toAID(request.user);
    switch (_registry.get(token)) {
      case (?token_owner) {
				if (AID.equal(aid, token_owner) == true) {
					return #ok(1);
				} else {					
					return #ok(0);
				};
      };
      case (_) {
        return #err(#InvalidToken(request.token));
      };
    };
  };
	public query func bearer(token : TokenIdentifier) : async Result.Result<AccountIdentifier, CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_getBearer(tokenind)) {
      case (?token_owner) {
				return #ok(token_owner);
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
	};
  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(_supply);
  };
  public query func getRegistry() : async [(TokenIndex, AccountIdentifier)] {
    Iter.toArray(_registry.entries());
  };
  public query func getTokens() : async [(TokenIndex, Metadata)] {
    var resp : [(TokenIndex, Metadata)] = [];
    for(e in _tokenMetadata.entries()){
      resp := Array.append(resp, [(e.0, #nonfungible({ metadata = null }))]);
    };
    resp;
  };
  public query func tokens(aid : AccountIdentifier) : async Result.Result<[TokenIndex], CommonError> {
    switch(_owners.get(aid)) {
      case(?tokens) return #ok(tokens);
      case(_) return #err(#Other("No tokens"));
    };
  };
  public query func tokens_ext(aid : AccountIdentifier) : async Result.Result<[(TokenIndex, ?Listing, ?Blob)], CommonError> {
		switch(_owners.get(aid)) {
      case(?tokens) {
        var resp : [(TokenIndex, ?Listing, ?Blob)] = [];
        for (a in tokens.vals()){
          resp := Array.append(resp, [(a, _tokenListing.get(a), null)]);
        };
        return #ok(resp);
      };
      case(_) return #err(#Other("No tokens"));
    };
	};
  public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_tokenMetadata.get(tokenind)) {
      case (?token_metadata) {
				return #ok(token_metadata);
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
  };
  public query func details(token : TokenIdentifier) : async Result.Result<(AccountIdentifier, ?Listing), CommonError> {
		if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
			return #err(#InvalidToken(token));
		};
		let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    switch (_getBearer(tokenind)) {
      case (?token_owner) {
				return #ok((token_owner, _tokenListing.get(tokenind)));
      };
      case (_) {
        return #err(#InvalidToken(token));
      };
    };
	};
  
  //Listings
  public query func transactions() : async [Transaction] {
    _transactions;
  };
  public query func settlements() : async [(TokenIndex, AccountIdentifier, Nat64)] {
    //Lock to admin?
    var result : [(TokenIndex, AccountIdentifier, Nat64)] = [];
    for((token, listing) in _tokenListing.entries()) {
      if(_isLocked(token)){
        switch(_tokenSettlement.get(token)) {
          case(?settlement) {
            result := Array.append(result, [(token, AID.fromPrincipal(settlement.seller, ?settlement.subaccount), settlement.price)]);
          };
          case(_) {};
        };
      };
    };
    result;
  };
  public query(msg) func payments() : async ?[SubAccount] {
    _payments.get(msg.caller);
  };
  public query func listings() : async [(TokenIndex, Listing, Metadata)] {
    var results : [(TokenIndex, Listing, Metadata)] = [];
    for(a in _tokenListing.entries()) {
      results := Array.append(results, [(a.0, a.1, #nonfungible({ metadata = null }))]);
    };
    results;
  };
  public query(msg) func allSettlements() : async [(TokenIndex, Settlement)] {
    Iter.toArray(_tokenSettlement.entries())
  };
  public query(msg) func allPayments() : async [(Principal, [SubAccount])] {
    Iter.toArray(_payments.entries())
  };
  public shared(msg) func clearPayments(seller : Principal, payments : [SubAccount]) : async () {
    var removedPayments : [SubAccount] = [];
    removedPayments := payments;
    // for (p in payments.vals()){
      // let response : ICPTs = await LEDGER_CANISTER.account_balance_dfx({account = AID.fromPrincipal(seller, ?p)});
      // if (response.e8s < 10_000){
        // removedPayments := Array.append(removedPayments, [p]);
      // };
    // };
    switch(_payments.get(seller)) {
      case(?sellerPayments) {
        var newPayments : [SubAccount] = [];
        for (p in sellerPayments.vals()){
          if (Option.isNull(Array.find(removedPayments, func(a : SubAccount) : Bool {
            Array.equal(a, p, Nat8.equal);
          }))) {
            newPayments := Array.append(newPayments, [p]);
          };
        };
        _payments.put(seller, newPayments)
      };
      case(_){};
    };
  };
  public query func stats() : async (Nat64, Nat64, Nat64, Nat64, Nat, Nat, Nat) {
    var res : (Nat64, Nat64, Nat64) = Array.foldLeft<Transaction, (Nat64, Nat64, Nat64)>(_transactions, (0,0,0), func (b : (Nat64, Nat64, Nat64), a : Transaction) : (Nat64, Nat64, Nat64) {
      var total : Nat64 = b.0 + a.price;
      var high : Nat64 = b.1;
      var low : Nat64 = b.2;
      if (high == 0 or a.price > high) high := a.price; 
      if (low == 0 or a.price < low) low := a.price; 
      (total, high, low);
    });
    var floor : Nat64 = 0;
    for (a in _tokenListing.entries()){
      if (floor == 0 or a.1.price < floor) floor := a.1.price;
    };
    (res.0, res.1, res.2, floor, _tokenListing.size(), _registry.size(), _transactions.size());
  };

  //HTTP
  type HeaderField = (Text, Text);
  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
    streaming_strategy: ?HttpStreamingStrategy;
  };
  type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
  };
  type HttpStreamingCallbackToken =  {
    content_encoding: Text;
    index: Nat;
    key: Text;
    sha256: ?Blob;
  };

  type HttpStreamingStrategy = {
    #Callback: {
        callback: query (HttpStreamingCallbackToken) -> async (HttpStreamingCallbackResponse);
        token: HttpStreamingCallbackToken;
    };
  };

  type HttpStreamingCallbackResponse = {
    body: Blob;
    token: ?HttpStreamingCallbackToken;
  };
  let NOT_FOUND : HttpResponse = {status_code = 404; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
  let BAD_REQUEST : HttpResponse = {status_code = 400; headers = []; body = Blob.fromArray([]); streaming_strategy = null};
  
  public query func http_request(request : HttpRequest) : async HttpResponse { //I have adjusted the display of tokens. Replaced the <svg> tag with <div> and changed styles (Eimolad change)
    let path = Iter.toArray(Text.tokens(request.url, #text("/")));
    switch(_getParam(request.url, "tokenid")) {
      case (?tokenid) {
        switch(_getTokenIndex(tokenid)) {
          case (?asset) {
            switch(_getParam(request.url, "type")) {
              case(?t) {
                if (t == "thumbnail") {
                  return {
                    status_code = 200;
                    headers = [("content-type", "image/gif"), ("cache-control", "public, max-age=15552000")];
                    body = Option.unwrap(_assetThumb.get(Nat32.toText(asset)));
                    streaming_strategy = null;
                  };
                };
              };
              case(_) {
              };
            };
            switch(_assets.get(Nat32.toText(asset))) {
              case(?asset)  {
                return {
              status_code = 200;
              headers = [("content-type", "text/html")];
              body = Text.encodeUtf8 ("<div style=\"display:flex; height: 100%; max-height: 650px; justify-content:center; align-items:center\"><img style=\"height: 100%; width: auto\" src=\"https://"#asset.canister#".raw.ic0.app/?asset="#Nat32.toText(asset.id)#"\"></img></div>");
              streaming_strategy = null;
                };
              };
              case (_){
                return {
                  status_code = 200;
                  headers = [("content-type", "image/gif"), ("cache-control", "public, max-age=15552000")];
                  body = Option.unwrap(_assetThumb.get(Nat32.toText(asset)));
                  streaming_strategy = null;
                };
              };
            };
          };
          case (_){};
        };
      };
      case (_){};
    };
    switch(_getParam(request.url, "asset")) {
      case (?asset) {
        switch(_getParam(request.url, "type")) {
          case(?t) {
            if (t == "thumbnail") {
              return {
                status_code = 200;
                headers = [("content-type", "image/gif"), ("cache-control", "public, max-age=15552000")];
                body = Option.unwrap(_assetThumb.get(Nat32.toText(_textToNat32(asset))));
                streaming_strategy = null;
              };
            };
          };
          case(_) {
          };
        };
        switch(_assets.get(Nat32.toText(_textToNat32(asset)))) {
          case(?asset)  {
            return {
              status_code = 200;
              headers = [("content-type", "text/html")];
              body = Text.encodeUtf8 ("<div style=\"display:flex; height: 100%; max-height: 650px; justify-content:center; align-items:center\"><img style=\"height: 100%; width: auto\" src=\"https://"#asset.canister#".raw.ic0.app/?asset="#Nat32.toText(asset.id)#"\"></img></div>");
              streaming_strategy = null;
            };
          };
          case (_){
            return {
              status_code = 200;
              headers = [("content-type", "image/jpeg"), ("cache-control", "public, max-age=15552000")];
              body = Option.unwrap(_assetThumb.get(Nat32.toText(_textToNat32(asset))));
              streaming_strategy = null;
            };
          };
        };
      };
      case (_){};
    };
    switch(_getParam(request.url, "index")) {
      case (?asset) {
        switch(_getParam(request.url, "type")) {
          case(?t) {
            if (t == "thumbnail") {
              return {
                status_code = 200;
                headers = [("content-type", "image/gif"), ("cache-control", "public, max-age=15552000")];
                body = Option.unwrap(_assetThumb.get(Nat32.toText(_textToNat32(asset))));
                streaming_strategy = null;
              };
            };
          };
          case(_) {
          };
        };
        switch(_assets.get(Nat32.toText(_textToNat32(asset)))) {
          case(?asset)  {
            return {
              status_code = 200;
              headers = [("content-type", "text/html")];
              body = Text.encodeUtf8 ("<div style=\"display:flex; height: 100%; max-height: 650px; justify-content:center; align-items:center\"><img style=\"height: 100%; width: auto\" src=\"https://"#asset.canister#".raw.ic0.app/?asset="#Nat32.toText(asset.id)#"\"></img></div>");
              streaming_strategy = null;
            };
          };
          case (_){
            return {
              status_code = 200;
              headers = [("content-type", "image/jpeg"), ("cache-control", "public, max-age=15552000")];
              body = Option.unwrap(_assetThumb.get(Nat32.toText(_textToNat32(asset))));
              streaming_strategy = null;
            };
          };
        };
      };
      case (_){};
    };
    //Just show index
    var soldValue : Nat = Nat64.toNat(Array.foldLeft<Transaction, Nat64>(_transactions, 0, func (b : Nat64, a : Transaction) : Nat64 { b + a.price }));
    var avg : Nat = if (_transactions.size() > 0) {
      soldValue/_transactions.size();
    } else {
      0;
    };
    var tt : Text = "";
    for(h in request.headers.vals()){
      tt #= h.0 # " => " # h.1 # "\n";
    };
    // return {
      // status_code = 200;
      // headers = [("content-type", "text/plain")];
      // body = Text.encodeUtf8(tt);
      // streaming_strategy = null;
    // };
    //x-real-ip
    return {
      status_code = 200;
      headers = [("content-type", "text/plain")];
      body = Text.encodeUtf8 (
        "Eimolad Dwarves NFTs\n" #
        "---\n" #
        "Cycle Balance:                            ~" # debug_show (Cycles.balance()/1000000000000) # "T\n" #
        "Minted NFTs:                              " # debug_show (_nextTokenId) # "\n" #
        "Assets:                                   " # debug_show (_assets.size()) # "\n" #
        "Thumbs:                                   " # debug_show (_assetThumb.size()) # "\n" #
        "---\n" #
        "Whitelist:                                " # debug_show (_whitelist.size() : Nat) # "\n" #
        "Total to sell:                            " # debug_show (totalToSell) # "\n" #
        "Remaining:                                " # debug_show (availableTokens()) # "\n" #
        "Pending:                                  " # debug_show(totalToSell - availableTokens() - _sold : Nat) # "\n" #
        "Sold:                                     " # debug_show(_sold) # "\n" #
        "Sold (ICP):                               " # _displayICP(Nat64.toNat(_soldIcp)) # "\n" #
        "---\n" #
        "Marketplace Listings:                     " # debug_show (_tokenListing.size()) # "\n" #
        "Sold via Marketplace:                     " # debug_show (_transactions.size()) # "\n" #
        "Sold via Marketplace in ICP:              " # _displayICP(soldValue) # "\n" #
        "Average Price ICP Via Marketplace:        " # _displayICP(avg) # "\n" #
        "---\n" #
        "Admin:                                    " # debug_show (_minter) # "\n"
      );
      streaming_strategy = null;
    };
  };
  
  private func _getTokenIndex(token : Text) : ?TokenIndex {
    if (ExtCore.TokenIdentifier.isPrincipal(token, Principal.fromActor(this)) == false) {
      return null;
    };
    let tokenind = ExtCore.TokenIdentifier.getIndex(token);
    return ?tokenind;
    //_tokenAssets.get(tokenind);
  };
  private func _getParam(url : Text, param : Text) : ?Text {
    var _s : Text = url;
    Iter.iterate<Text>(Text.split(_s, #text("/")), func(x, _i) {
      _s := x;
    });
    Iter.iterate<Text>(Text.split(_s, #text("?")), func(x, _i) {
      if (_i == 1) _s := x;
    });
    var t : ?Text = null;
    var found : Bool = false;
    Iter.iterate<Text>(Text.split(_s, #text("&")), func(x, _i) {
      if (found == false) {
        Iter.iterate<Text>(Text.split(x, #text("=")), func(y, _ii) {
          if (_ii == 0) {
            if (Text.equal(y, param)) found := true;
          } else if (found == true) t := ?y;
        });
      };
    });
    return t;
  };

    
  //Internal cycle management - good general case
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };
  
  //Private
  func _textToNat32(t : Text) : Nat32 {
    var reversed : [Nat32] = [];
    for(c in t.chars()) {
      assert(Char.isDigit(c));
      reversed := Array.append([Char.toNat32(c)-48], reversed);
    };
    var total : Nat32 = 0;
    var place : Nat32  = 1;
    for(v in reversed.vals()) {
      total += (v * place);
      place := place * 10;
    };
    total;
  };
  func _removeTokenFromUser(tindex : TokenIndex) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex);
    _registry.delete(tindex);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o);
      case (_) {};
    };
  };
  func _transferTokenToUser(tindex : TokenIndex, receiver : AccountIdentifier) : () {
    let owner : ?AccountIdentifier = _getBearer(tindex);
    _registry.put(tindex, receiver);
    switch(owner){
      case (?o) _removeFromUserTokens(tindex, o);
      case (_) {};
    };
    _addToUserTokens(tindex, receiver);
  };
  func _removeFromUserTokens(tindex : TokenIndex, owner : AccountIdentifier) : () {
    switch(_owners.get(owner)) {
      case(?ownersTokens) _owners.put(owner, Array.filter(ownersTokens, func (a : TokenIndex) : Bool { (a != tindex) }));
      case(_) ();
    };
  };
  func _addToUserTokens(tindex : TokenIndex, receiver : AccountIdentifier) : () {
    let ownersTokensNew : [TokenIndex] = switch(_owners.get(receiver)) {
      case(?ownersTokens) Array.append(ownersTokens, [tindex]);
      case(_) [tindex];
    };
    _owners.put(receiver, ownersTokensNew);
  };
  func _getBearer(tindex : TokenIndex) : ?AccountIdentifier {
    _registry.get(tindex);
  };
  func _isLocked(token : TokenIndex) : Bool {
    switch(_tokenListing.get(token)) {
      case(?listing){
        switch(listing.locked) {
          case(?time) {
            if (time > Time.now()) {
              return true;
            } else {					
              return false;
            }
          };
          case(_) {
            return false;
          };
        };
      };
      case(_) return false;
		};
	};
  func _displayICP(amt : Nat) : Text {
    debug_show(amt/100000000) # "." # debug_show ((amt%100000000)/1000000) # " ICP";
  };
  func _nat32ToBlob(n : Nat32) : Blob {
    if (n < 256) {
      return Blob.fromArray([0,0,0, Nat8.fromNat(Nat32.toNat(n))]);
    } else if (n < 65536) {
      return Blob.fromArray([
        0,0,
        Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n) & 0xFF))
      ]);
    } else if (n < 16777216) {
      return Blob.fromArray([
        0,
        Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n) & 0xFF))
      ]);
    } else {
      return Blob.fromArray([
        Nat8.fromNat(Nat32.toNat((n >> 24) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n >> 16) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n >> 8) & 0xFF)), 
        Nat8.fromNat(Nat32.toNat((n) & 0xFF))
      ]);
    };
  };

  func _blobToNat32(b : Blob) : Nat32 {
    var index : Nat32 = 0;
    Array.foldRight<Nat8, Nat32>(Blob.toArray(b), 0, func (u8, accum) {
      index += 1;
      accum + Nat32.fromNat(Nat8.toNat(u8)) << ((index-1) * 8);
    });
  };
  func _clearMintedNfts(){
    //unset metadata and registry...
    _supply := 0;
    _nextTokenId := 0;
  };
  func _mintNftsFromArray(tomint : [[Nat8]]){
    for(a in tomint.vals()){
      _tokenMetadata.put(_nextTokenId, #nonfungible({ metadata = ?Blob.fromArray(a) }));
      _transferTokenToUser(_nextTokenId, "0000");
      _supply := _supply + 1;
      _nextTokenId := _nextTokenId + 1;
    };
  };
  func _mintNftsIndexed(n : Nat32){
    while(_nextTokenId < n){
      _tokenMetadata.put(_nextTokenId, #nonfungible({ metadata = null }));
      _transferTokenToUser(_nextTokenId, "0000");
      _supply := _supply + 1;
      _nextTokenId := _nextTokenId + 1;
    };
  };
  func _mintNftsIndexedForAddress(n : Nat, a : AccountIdentifier) : [TokenIndex]{
    var ret : [TokenIndex] = [];
    while(ret.size() < n){
      _tokenMetadata.put(_nextTokenId, #nonfungible({ metadata = null }));
      _transferTokenToUser(_nextTokenId, a);
      _supply := _supply + 1;
      ret := Array.append(ret, [_nextTokenId]);
      _nextTokenId := _nextTokenId + 1;
    };
    ret;
  };
  
  stable var hasBeenInitiated : Bool = false;
  func _init():(){
    ignore _mintNftsIndexedForAddress(380, "53e8c1f6d3a6d7e6bc18cd1f56c34b68dbbbf90ce3c39d3a750154e02c467ee8");
    _whitelist := ["00239b48844d028c982d199a0039fcaa39853bd15f5d95ff32793a1e9814acbf","00610c36c21323a87018fb08f515ef2a4253c6288d78deabde6d32c5ce6b249c","014f2bf32b6a8da6d4855b204970ad072b39a0531714324924ce04e4afc6ff32","017fc7f5574eced6d23c84224fcc72f644b94263d3c5e4665a3f5f5736e4f5c0","0185ed4fe1b2f99c042a016e7467aaee7e0ca681c25eccded0fa27cebb832922","01a8bacc1e34f11fabf92eefcdea79c32cfc442a2291de0fa214eb9c83ad9d4d","01f224a754cd91143870b3fcfda322219efbf1741764f8ee8dbf1ac9ef554388","01f8883e5c38047eb661a6c84347c6c77e4f2ca9f659a0235906b5ed8cda576f","01fb2b241e825be68378041194061543ffc76ddc8053bc992b4f47a61b22ec08","02211b0258611247923932cfd373704ce42448fa01b431bd2cc1f5014b557e98","02282edb9afccf1560f897bbe5a25a2672cfbcf946593dc47d6c850d69dfef86","0234fa64dbabf822d4b58659b2bf3c6928b5e7146ee0b7052bf588f74ff9de39","0273abb96d8686eb527daf85a62cf69f6d2dda637f461efb224f3443b893bc99","02a89f09a4c310ad09edf50c8047077d3ffeb3153e532299daa2cbb8150525af","02b20cf0f699ef1748bc8c1030c764cf53840e4ae78e51d07f4e0eb5e59862ef","02e3498f7682f601db0a402de61cd79714f3bedf53d448bb211d164b823fc262","03d8c97773e4877d3442840a5a72433c2ce8430da2b478f64402f145665c3cb2","03e1a24f1fb2baa29bf89dedec4a2ec534ac7d0ddd1ba28e625ca813fdfecdfd","040062722ab0ba27661511bd9445ae79e2d639ce700afaa6b730f5b56789c8b4","05f2b32d11e6c0f8da0d9b1d812f4d7d6ffdb81288f7d39e4e4d502553cc6525","05f3e5842bb2cbff6316d6569d280042fd17f852f9251b32241f33e21b0ffd35","0601ec11e260406246e472e90b45bf27ef67c4e1457cf432b2c2ca84c05de5ea","06921b5b39105d6393f1d1a2c9c6edef11edf97167f3e78a0fdfc8173dbab096","06d75cc93a2b88f79ff4906f27cec7a508c2a37578bfe252eda1ee53ad5bc6f9","06dfc1f3a0a60374eba18a62b22f8a05dc962c4856310eeec7033f416963aefb","06e383a5118c797d0861fc01249180ddd98d12d2648b21129a9e120fa2291757","072c4065e407392b158de3192818dc27ef5035d5dadaa779b436233f8b5eb65b","07393d0fe7547f9dfdda2c879c1490dd81675a3d160f9c4940efecbdcb6c11db","0743fccfa29a009676f1e759ae5c3744bb93a19db90bad2e65b9bd2a9dfe0fd2","0747029cef30e9dcb6057e0916e2f0291f29f8a7f1c12bcb6277e3804db8110f","0747a41f576528de4d9a82c5a7c792e48a9d2b545a49cefc529173e9f0c0fdc1","075aad1ab6336cdd92c5ba6abf8755abac5b9e11c208f2e6286f1e1635a4016c","075b765fefcc9c965312af1f3e0ccb44c090f6ece135db1f6f649e037c9a4fdc","07deaeb2a584aa38851e7ddecff3fbf75e7172f1e7c6a15ad01c317ee226f32e","07e717dc398daf6f23034e0f166cddf4c1ed99ec6c840cafb10ac71ac0d990ac","086d2c073f6cf57b2d4deb3371fec25c00a5676c767720ab9006a093ecc89d98","08a8f7e278b0e210a70c35be3254c3ca4d1cf2e983974ba33d7f61fb84277c50","09792fd06fd0c2ccc0fb0b8bdc9b2ceb1a4c84b99cc68e4c712ff975a249e425","09e3ca1d8f6231dfe26850103546583d20759a046b7fcef05d392ee01699b8de","0a46a9e84636954e33e8616010f70da4e0e6f8cc1890258d73b53dbff057299f","0b4b4c75e1a365410c068688bffe4827fc9e32eac13fa5cba4d771aa6501e84c","0b666563052bd9dbde0032059285702402ed3a7d430550141f7da1fccef02fa0","0b79f7ff16b8241fa5529936becf77c52ecb75c5db3a1dbbeff1aa71c44f40ec","0bca69ea6a8be3a709779e939b97dc65d10c94705fbc80520f1e3e3c284731f3","0c2516221742754b6eeac932c739d22d650952bc15cc6ee4a7ea56c8e45d1846","0c41af08ff89969d34032666e34a8ff126564896574599233f267b53c5a46a43","0cf414c46e13617004eb6c2919a2aa8120e13b2cfdae0e8d3985f0bd760e6129","0d99fc8adcd9c8db74ac7a90dd2e97e0c5c3020a019d050be52bc2a720453722","0e30621d41c10fcc258ac0bbe9e5a26363993ac6fbd4002bf21904be2e808d84","0e7047ca63a8641cfa38a3400c68de87d8ee4935cccfc59eef47d23743035a15","0f0e00dceeb40bf41e396551fa45d049a4f981a6976c23a06aec4178aef24f09","0f2f750148b9736b1b2fa4cd384440ee72f6f6916c21504d4a48a71c423335d5","0f4f58e8bd78e11074d82f40c6d9199d7da3723ff00a039601aa9bbcd6f91b6f","0fc2b3811f84c8287bcad15f88590f0a063b24cdbb3dc8010f94749524374329","102c1968647759e224c63ec5f68a5343dad5589a46b04abd39ecf667f83c7f72","104b0e976d932440be1064a05cc8d594e77a28c8023596888b1a0da19c5f3737","10d1787ecb14569136818e4c9f2a4a23bd988e19814173557efa28b33f305f7d","10fd8b1adcff2c106659e80a34178c9d6b5146843386edd2663dc01f867b2502","115d995332b85fb8102cbaec8bd063491aa8add6d7b179872b98bc03f3e13fa5","11b11fd680425e2d4d36cc28c7f7ad043e607baa6f0bca5fc33fcf75d12901e9","128edc5c41ad8956005eff21311d34195b3893d52a9cc7a2f72b5c03c517a23d","12bc158b6aad670322f4bfc177b6fc61bbb51d02816fcc26fb187ed9301df7ce","13d6f1fca4d548e06dcf0054cf357f6099dc23aa9ba909c31c881a8e531edca6","14b82acde35c1d141345a5ea27b9cc46796e9d01a7f083d92c0c33c6a4adeea7","14c1e23f64b546ffa339cf4a77394990b837269c777b620ec18b3a56e411a3b2","14c3230287a74df7ae7ddccf0d4e8bd8b230cd2ad6c5262af5f0d4e2b3079432","154086e1257189f701cffea8785cd500771f296ba69c7858bf9c72c3d2da7205","1573fea497743b2808009020b29c21fd45a3d5d42132418a6a01c0793c977ef1","160593022d1c4d551c03a0f904169433658e68d658c36ef0e440daee6d041d96","162f76b16fda8774ed7e2ceb2eef20c67288b17893b8664d885382ce14949d4f","165c09bd259e927ac6b164190fbd2fe67c747872659a02010b34e2d824aef73f","16a8588e4f074b2ed00ff1f845c391ec6aab57e63576152756ac67c7cf8e925b","16e3be893a79bdcabb06e7f052c427028336b629ad94f4d860f85ecee72f90f3","1722887585b30c7e5d527d70332787d8c46e52f5be50967e11eff405a92b4de8","1725336af3bb34d067754c5ba37f5feb4444aa08fe8175b6606213f2781a20d3","17dd430e2582d0274245b5a01885b5b8ff0a0dba0bf916418858ab62738f605d","17e73cdbba7ea77179754d3c81d3303e5eb47b3532396a4188c7f515c14328c7","1875b250e3a740fbfab94217735d4ca4970d176cef8ad983763aa0ba341be039","1939ae0d38e14a78290c822c2d98553fae16fff58fbc8dc48c399d7ae169a817","194da351069292319e2700a2b633288511a9ff131ce246f46d80683bdb90192d","19d448c37d267e3544e3a063535812277872f3fb0d7debb6280d7ddcf8c6c82e","19e73e555c3dbe1b60efb37bcd6ca00a628dc12d4b692ba313317d82a1ff727b","1a0f3b35256749016c158f1f90095ebc529924feba7663c37beb293fc3f90a16","1a96f7857beef47553c674737b90a73acf087147ff68e480e5170344df8f9b0f","1ad30f3cb43b2d9765f1bfa362fb37950c1e275add614e86ca9dbecd78365786","1b07d6d3410a112aa78be3d2279255783e2018b7dd75cdf1c9d834067a9ee214","1baafff43feccd6758c2c1f74f3d8ca6dbfbcba77a0e229f5522d76774c8f592","1bf6e68a9e684e0660803eafc56b1aff9928560825ae9b01b3a1e21211a8dad3","1c56347e19e02754220bba24fd10d1d0120feeff6848bd47a6f0ef3ed5ced552","1d0401393dd7ba0c723b686fb1be5982069ca2e1628198067f585e3be7afd7e3","1d497b337aaee55bd9a37079733a2586268b971e451ababbaf2fd19f04d8abea","1d98bef99e9dad7d0d5e9bb013d254fb610a2033732ab2c5c1fd2ccbe3c368c3","1e032faca8e737e9935f06e143f1294be81b830171cd66f30c9fba7419e5f4f4","1e0bdfe2670a655efee77c4952ca04232a751c51f2aba811402ee6aff69a70ea","1e42532407dbeaafa1a45c19be8a6e6dda5ea10900b5b2596ee91053403633ed","1ef3c9cec820c91fe0ac7aca40de555abf12098df8debde11c66e9b36a4c3593","205b3abd23bdb8a8b76f623c78c71c8fb7aca1c7099af2a5d7e41a35222e8a0c","208b317411bcf81ce28a61c185d363df872bad793b429ef9445634fa8b716ed6","2099bccfe4a6060a6df56e5b1e66f8e546f9004a1d3decef619b393c94017342","20f0a47cc958ad3bd79cacfbac4f902bf6505cdb6446569ba7ed1d2a03a8f712","211cf4d37f263c3a1550b8cda99ab249888b163e478b7dd0f4ed2f92e8e95c93","212680235551887e6f2ea1b79a504c19b83f0855e9fc78c4b8ee94b460990786","21874b081e728ae67fd02772ea6de0126adc3dc2d7d51a4e0398b5945c998765","21b6d809f843be116a9f999e72ee3dde1b66ad468c496909d3f3197c751e2256","21dd2072af6c3c8b70d0af70efeb2745ca3cae3435d76fdf693ee475a4770637","22549f74995a1b201b987ed5b8da5cdfc6791d3d511c7c2de7536c765ed55138","230d40411350cddcbc3e27ed12b869f71f1c4a3e3d6db343fe1f14791067c9bd","230e854efa3eef3bcfef5ee893d3bdbe98a6ed702892581cc5632e6a0b23636b","232bd1115a7438064be1b64bd9626072d023b2ea5fbe78184309e02cc8a0698f","2408dc937d945505b9d36c9fba59d002839a607f81fdaffab54f099d9040f414","244a626e2133eaf9b4f7e4b55feffcc77327136b2bf41e202ec7028340b5fb2f","247a757a12d9e0492d5f52fb129052d31f94dc8f600f432ced133e680cee3e60","2488372f1889fea55938a6b9aae6c8e15f3258d2e7e985aaab27a805bb78def6","24bb440909741360280abd57aaa365abbc4180fcfdd60b6c387e4d7dbb71c9cc","24e68ff89f6255a7f3931409e83f62231a837f069ace99fecfe8faa7e1dd4f70","254916e1796041ccd7539d23310c4c6db14950c18f58313f14d98dddfe20eb8e","257b0d3f58bdd206d89e87470afc17a3b64310711e98a7abc68f23cecb6644c7","25b3234c5b1d40ac38758db74e68565e9b477f6e919fc596f77b1a3bf656a926","25bd29f244ed61c4d264b9b6ad60400d80793c408baa7e9ae76baea55d6634f3","25e10a04daddc5918e3df4ed46c5d1f9c554fc0b714d2842b81306f4ec9e7828","25e69224807e7315e4ca2feeb5eb024f22eb820687c4f74dce4e4a9b52c336b9","26219409c2635d9bc99d8cbb0e302f7fe022af9e1469fe382b1c3fb6b919b1ac","262a2c092dc41a72c95b5a18680df4a6b4768c15e670ec610086bb6496eb536f","279e43476a2c0677a1a61ad1ef6b568ba1a37486e580437df2abcb40be893202","27d26ccaa4975ce01b4ea5fd4681c7c1bde211506c5069ec0416773acb0fbe7c","2889821038689de3e5d2076fefb3298b65d9674383e60cdd38fafa2b0404708c","289b69545eba132491dbc945e2616501e237dc46e50c8b1a469ce8b54ec78bd4","28f927cb973e4b9c1f033f69fb087651215f156a987561554b05e60c17fa933b","294b442d9c29d0f8b2daef0142ca5d8f0957e379d7e0a5d2c1880211975ac5ce","2956777226f0baa50e78956882e915dc63bda6a025e97e6a45debf3cd8173c69","29b71ef0c3dcf1258db71c2811b591ad7beb6b98e39009550323bf05bbffc83b","2a97f12646ecf927dfeabe7df3b93d7657f51938a8f1e896b466f6e8e5ef8c31","2a9fbd0ff0ba49b66ddb91c17e6c9d2296b62e4c4a0d383e4b67f7d2cbf8f849","2ab6454fbf545174faf8447d08f809f0ffe11d257a1a691ed82611e1ad7dc12a","2aeab2fec7e25c56c622911d932d66b4343952e5bdf302b298c851a75412b5de","2aedf025918ea8897a3e7f2b6d1f1904a895c839ca148e529f832d11f83b0a72","2c32168791e5c3d6b44f12b00a38e43ac7fc72ec80f8632f9a7a4701a7b23abb","2c7151274458b580cf1a0fd2f4262c202b10845055af61c74feeb465192e9023","2cabe74f92bb4abc138bcaad4548984d89c8c6303558cca9d5e379a629621aad","2cd9ae26ff99d9006f4129047e6521d5c08cd989aa7d2a6415da1363a5f13a3d","2d017408258948f2013cc2d99de0ac9fd22e4a2f84b6fe335559726073d60693","2d2444932d19aaa8f769944a720e814dbaf072c709716a2d21efec320b415494","2d30b6bdfa0b7f3f6e1c68d9cee2c3e3034f222d3d5935be28cffbf43146a258","2e103d94f383f2ea0d89e9ea8671e16782f2220e4d919f9541c9f45db31e1212","2e9bb771360c6fc1010abfa26c5cf498338deb63d98008eed23437f40771e0e2","2f232960d8f46070c1bc18f3479f9b6a417bbc6439dfc1bee1af75303462f477","2f369c785099d20219f35ef8d7bcbde25bd43c49a853f41f7e28dcaa195cc7a9","2f47e3277c37ff8d6525105497cf1beb59e463c177eb491157c0b7b86af8f70e","484ff914e1369a60a82c1d216ede738b7b9bdd0e6e1166569a10331e63d56dc9","3033418d86b83ce29be3e3f5763843c376728ee1ab6179dce14d64570fb4e36e","308bf7136f2fd2abf309ece0986dc968fec0ab65e65d8aa2883b7da555d04e0a","310cc5f688f1b7b21a83ff9f255f0ada1fc411c58b3ec4f31bb8db5a429ce673","31d7f106250732eb5299056c4cbb6209eb53cb0e7204f5a5a91bdc4fce84ce08","326c011908fe538aba06ff540dbb2721d072723a02f49d0015a0c0f9d7d962d6","3274aee35adf1358eed302397838ef139283d9fb8fd250f6539804eb9974a008","32d00ddeb59f42481a382df21b035ac00002cbf6a24bb04138c8a2670b73adbc","32e158de027cc949490af9c6336a0cdc23985eee86a7054ae69d1e7396ebba8e","33ffd36357854c729a91405ad8d49898ed8c3a83c6db59e353a211d986f78c42","3496ccc519f4f67acbed07b7ab74757da29f720341f14506db945b64c34c5c43","3502340091d4c58ec2b71383abedf34102bfb8cf217c264870effdf000f5656d","35267e873ec29f6aae079f5050995b9a7df87290662e098c34f821dbb02e816a","360907217814bae548fc4fb596a8b0f9f7e31f3555edad4dbcf9d892c972e92a","36117a4102b241effedeaaf3b7757967f994ec9fdfca1217b307716891ecdad7","362ce575ac18a17e178b44e0176c5516ce273545c890c922de24544a6373c4e6","36c976f1abd40d1da84406164386c1e8f321eed3e7b3d933e45a4466e7655072","36cd44a6e3568bca7cef1e49a866bd88524a836b8e160cce8a9e535f060dbe68","36cedd77f349f392c2bfd14610a883efa5b9f919b05ff7525c6c5760b0d0046f","3780845e9d9266c53bdfbac568f2deaadb5acbf79787e25fb1c171331929d928","37b5c21d6227e8a9024fbeb6ba4c025a96902391c157aa2dfc4373de5d378707","37dbcd84143ef13fe061297d5c57db4248176e6c3c11220aa26eba53c7bde969","3801194bf7826a9670d377dfb41e589bc4e75fc298262f29bc381295d3a34fed","38135e574c9d6c91f80060b56666f903e8afba60d14c464e95ceb042d48af9cc","39429c59e45905fd32815ba7a8f9effd829c8ba241ad012fbf1e2b5cdda591ad","399232f7d45cbe3956b5b2999fb7db8bf2fe76b99a293ddd458b21edad783b6a","39a002bee8cadbdbff2c6154c83a6ee883a80a4c615f29cf6ceb3660e59f863e","39a64e807e6c1dd4b324aadd3ad15ba02e498a9c1f00116ca5c27fa8decfcf75","3b08035c106d20549fe088c05fba318a4c9d83f2b5323e8d26b465adb4a9dd6e","3c1c4335b26c33cafdca346322a110a65dded91d4a11a00ffc3c277385c28a6c","3c54d6e26d02b9836582ee7058ecf4855e84b1c854b9cf40d02b0bf6653c11ad","3c9d12eace35bea96d7c037fb87722f3237aa2a9fdacd4069bba25a2103154b7","3d541fc526085d413e8c1e57d73a9f0bb785104877777458350ca5d593a8c736","3d757a301701a0e97d70959cbed01caf0be543abbca1c54c784f0c989ca7edf4","3d88ed528b3c672a0eceabcf92e569730243158af9c3777f168ac09ceb96d31d","3e03758c8f30e1c6e70dd0ed4771210554371dbf90a34978ec253f859c64a28a","3f00a1caed00cd13290ce00af07409782e1e271b9f4db25f690fa9227038b38e","3f79946317db594abe9f6c6cf0fbe22e026c001934dc8cf87f8f6fdb754f48cd","3fe39de7bee74f71a218ce30463bb5c3ce469f6e0ba006d278adda0183037fa6","401495adcaa797d2f0f5587d810c239f78787ed8e3282a856e0bb6e152145335","40d3a835aa5109111a06d2838f77d062259438ee7ec7936d5f02199bb5154d81","410f4b72cca9615e3e4949f0d4729b0cb157bd5d27dd5eea3ef4cc885673f5f0","41753943cf2811f4abd6f4373426768b48f5ffcaef31d8dc003af1ae442eebf5","41966f0a6757b854aadcb010266d44f7d97fdaf72c20c74315263959401be29a","41d1f190f1098204abb9c106e8f497ff7f2d9bd3961c0907062144132420703c","420098ad40a555a0000aed66cefcb08fe380ab12d2d555ca9536a8918d76f472","42be0cf9034b660f4e77347548640e29ab0a1402d468e8cd851765bce1bb04f2","43177eadc1985a577ae5fd7a93cee273364a83194df18a51961dbe262c1e159e","43537493d0cc2d892856929bdd40af12b54478b27c210da52f8a37c8c1bc10fe","4365da6c5893c7ecbc0288a5f1565dada82298226bfd37c83c014686bb31bffd","43c26bfd22a53996fcd489ca97d0e74a2a3f4b46b436e2038a936361d5066e08","43c97bbe0558a73c5853deed6846a191bded3b3362278bf4806d2879318b59a9","442c6b303c709bd1705833c9b773aee8e739b6f4dd43cd8faa377e192f074460","446be8aa4bd06f4c85c3f7f7bf6742807729249eaf3bd9bcda21025a14c167d0","4513418334bacd2800a92b89b4ddd52d450c618807fe486c9217f3bb1dad5ef5","457aa32dc50ec5684c177354f7a27773069815dad732d598823fdb4f2a5f819f","45b58e9c7377083f9a731443edcf6228485ce133a09c477c9b122908892ab9a7","4629a0e8f45ae647f1d3e463ce8320d0d028f30115a354caa9249b2fc246c427","46528c33c255652663bdf305bf3dde5064df75e0f7a84ca7d5b1f0334ba71f9c","46cecb2ced9af61b145755c887b7a27ecf013b8b4909c95c20050f5de140c754","471efeb26b914b2687d25348081a033137f8fdc3f41ae20e381ec69cc75c3ea3","4743240db87fee6fe5fe0a4e26ae7b434d3e469304b4e3dfea1abc9a6a6c25de","47d6d19264efe042779557cc6ed17e0b2731131b667237ebe63b3678c0547882","48f7a63d82cda1404455bda36918c64cb11978cddbe03b02eda4406a1b0ccf39","495f5ce737bc3824b1a4bf13076262102b2a1f99fc70379e15c5e14e4903f3fc","49e622315e38c708ba7f81a35173ee52b46c8004a8559a1a476773d7984db66a","4a15b0deb18be5b7df364d31725fe34b227f850bfff6655d389eb512900bbf9e","4a174ea2824465b92354b3a4a88ce2632eff04ea49f96b75823d605e0dbadbee","4a40805093c4a2f5ea52f54301c0f60bcb4678a9dd88e6f21fb12cdf5b982514","4a66eed26601245b3c3c90578aee7c547399619ffdf99d83599109b592a6e33b","4a9f5a4edc2cc10d2680e70e9d9c574bbc35a2c70fb7c1a2f7f0b2aab2dadf47","4abc96c158d21ded4b67c51b088919cc7b55f00be539e53d8830e33c64e275a2","4ad7559455a37c56f20f6e10fcda63f2a47523a97e966fffdc0114004300565c","4ae7f96e7df3009d9356531ddca3a5c9bd4d2d55fce67c9c8c3215b8b1921424","4b0e4315237216979ff49703b8b8e6f5857a249547c002b9e7898f56522b1f8c","4b1274cf03e31cca8be341376b8c3f32eb03b893a86a66e3a5a055bb8b471610","4b1946110e83cb7b01143d30450dc22d01a1b8fb3436caba4dd43bf4842fcfd6","4b3d496c927e5d1ee4117c35ffb1a400b278e5e6edb18928169b0651459e2367","4b4d1247986edddf25c44c2bcb177608162cd48d21d9da5f8b1a905f6c05fc9a","4c756925dadae488d613c8ee66b0589f5d3a532c4f4ac3de27e27663fb55e3ba","4c99406213f2d0511919a70d3417357466896fd0c4d7f1dea4613a611c47728b","4d22aa93b87ae10aa84326952e8aad609df6675fcfcdaee1b00271c8f1612177","4d5b4c1512516a6308062c4ecb5bdafecc04b3f4f9411f1de070d50123d0cc16","4d8006b35513e1f70e4a80d6c646aeef516d673d9d833e9b2100f7a111f5ea59","4dd8b13b83f392a08fc3e5f14ef1e2c708e9c210fa02b77741808b192ff10ccf","4e044b4a5b17551ebb0932211297c8d24c5c501521bb42174495d32655e08807","4e352ef318dd4a3676cd915fa8d24d56646474b8e91b614fa39b3f9987177373","4e8795165822cfe96b288bd2695fee6982f8bddc66adf6ade76d7f826d00a8da","4eaaf9eeae9ada10d69756ceff18e57f9a97564aeb6256be04efb2afb1724490","4eed34ae77adfe3c45caaab523acad0884d8dbdd300b4334d0251544f94ace0b","4f0a40f1e24fdac90cfa87d7a0a3427aea78dc0cd6b046ba3497689343a2852b","4f35460f1d934d99e57620dcc0d1782789b2aac2ef07d8f68fcf9bb7fe5f77ea","4f856e3c5517a45923654cd9253fbbcea3e7aef137fd1a5afd444e517247bb7c","4f8a4f7639aa944bdd84a00008b3a347587e117a8d61f8eec1c64182a1b2af8a","4f8ffb0bd089d38c835ae3c4f9d06f25dc48e37252e9de63aab929708c023e3c","508004a2f73a40d7a1b969efdddadb99e93a57cab2ca0201da077a6f19c58a20","5083135838385ba28cc4c6614674d0aaab070969cc8a8b9937482bd5d4ae16ce","5143d51ab8e2365e8b05b6e77279673710f0328ad8c70b2c6ed6911a34dd8768","51bc68be6110ad92ea19b523e2e04002fb6414bdf8df3a5ed6cc74941fb7a815","5205185f706657e73e9c6d23a913f80f071486504c9e138cdca61cf19688e7c2","5207daa6bab0944e7568e2e89cbe415a97a454af6bef9c87494b7aa79e8887fd","5224539dcde54241637cfc9ef9c6d2f2722535a4a7fbb1a4f04d770fb15e22fb","52e320344262523141030b4143a8339c595b77e5e5f2a0576e1a286169c04b7e","52e3ae95365778915dd75e595584dd101b1e633af0b601f08e70a0bab87eacc5","52e797232deff638c51888c06c40a46383e50e48710e3eaa4e444e9ebafe3c4d","535c8bec5753a4635529671464ed457b80050749cd08e74d5e39e5cdf239f357","537021a2de2cef37f52d4c0e8eb413ca780f124cde62e1d71c86ca6df03d47a4","53c4181dd82f969bdadb0641e4b0ddba2222a959cd274e642a1e28cea4ef98b3","540c88f2b37a7844ff7c4d4c7edbd4e8841397191d7abef85363326a4ade0b02","5444e5e5dd057bda97ff7061be6a36d43ccc57c8242592878f2ede2dd6c6c429","54dbc1a1992102b6ffdeebaef9c77def777dc8f753f8bd3cc5dbb4cef9206769","553846454c5ac96ba3966d446d1c2eaf440a59e19dca4d08218e42cb0087a1f3","56009b67648295be0719abcfe01ba5dbf62b366c9dd4123863778cb5dfcbdbb0","564b58e7aee03b6fc4c98140dc65223e922db53d6f6e76fd6c92d2e675fb93f7","569c66b1ab7530ef553e85f97a2f792feab6c01d1f9754349d7505a18f8c02d1","56ae941856b6ade3aabe703c8781f671cfe0c13dff9774941420ca3b59a544e2","574cb968c82d8874fd15a3a15bd33bdfcf6438af817e9ac06d1e1596e979e6ff","5927bea288abd92ab114dff69ee5c87c34faa17592b48261175f26326447f08c","593932fd896a89a5e27fab7d8f46844e91ce5e0703d5c079c9528598bbb963e9","59551a7e94978958d25ac8cf48b5ffc4c4683d61e527ea16885a37b2b9f3b6dd","5999b6a00c3e5393643404b1e2cd393ec366aa54c350d82e293520c79208a6d0","59c2d99eeee43761850629e5cbc00f897b0bf039f29536aa0f066ddddd858108","59d24b16f68b898e1802880dacf034dbc429ca99e334475d208dc23f701777e7","59fe1ba5f84295c1b737d0aa8b6211699f55896d62a0e141cd54b3ff5bea4e85","5a0a700af7b3cd470ca426084327af9c585985789fac00926b456ed3e17f8588","5ab59d93ddff0fa7794af7bf636fce7ecaf0551eb8a3b98129c1899068584218","5b0d0ef3f5ceb39709e808dab2923390826fbedcc62da14085a7a641a654cdb5","5b190b68e5cd310d13a4bbe94b40a3cc7e3a64abf49628a8113dc432020e736b","5bc9b5dca684aa2525ba562441c590632ddd76c48d6a6ceec6638c3da710ea45","5cbaaabe251f68b86989040942edeeddaad3fa411b0ca9c528f3e68229654941","5cbc75b2be1d3ba33df4380f615b7c818222c086ff2cb8358142e4e6afa62972","5d9368d3449434ea90a2e89c3f86cf0c1394284c146b49736afdc1e4ccb557e5","5df779b1970de9831a0e40224590558170b93cc79c0b352760e5ac29a9ad505e","5e168b2da2891a22e1d36e88934061e532e9b8359cad6368d3549f6eef99190b","5e508d1cb4b5e2de77244a2a0a91d43921fa50e3b15f52f2db086573ee9a679b","5eaf6d805383ceb7fa61541dd012ff700b7afad22a0a7c1fe2d4a6becefe9c3b","5ee9eca2562d10fd3ec292c4da58b07c270c3a27cff68bf6272a7f3719726b7c","5f4b12c6842c600001bda0dfce49e928d7e6a05dee3a49cb5bc21592e901f553","5f5f2ac581dfa51a9e9fdbe8fe090f2de8cd36ad23a33fc350ba738c0666a139","5f9b53a359fb10a150537e0e180f746ad2084a07f44965586443b66aca3d91a2","5fed2d8c8523257aefc20d70e085d30ae06cfa41ca636279e01f19861a468703","601bec227261843c435c87c90d95c1dfa4ac886a38b47f8fc22d3b7d00d614d1","608da2659161757877138ba7736b101e7cda4fc970601eb9fcb83f29702c48f7","61b34f0a0f21a5ae7fba178f71e9c78a97bca5e9bd02f9cfb23361cc70f89deb","61ed2e5b67d8076e05842ed296d9758710bc4b6a4c7f98f79b46a4476f98a4cd","624fb3258af090c3a47dccc8f07736f949f479b88c5cf407b20a313d393c9ead","6269d2ce1907ca01441cb3abbcc53eb4281d8449d1485b18ddad588c195f3883","629da11afbc5a178269828072de5b6daff248e1d160d35883ee6314560a9d3a7","62c58a5481eb36cb15b78021aa283aa2a74921c71aaf84230a24af7daa6627af","63d324deb9c2f070e1fe374e67e9c3b755e5c4e2fd20dce462be51f2e39ee352","63d8e042b82bb0e89c09a1d0867012f48a044306c789d2cdb84fc8028c69443f","63e4628db421b93ba941395f2b654b3b2587c9441cd71ff9295673d58b96cc8c","641fb400dadf9fb981a440d2e9e764332829dd5a7d9cea4c1305338a4b5a5e44","6423375c31aac1fcf49e07bdad180f08fea40b0c2ba315766682129db3d59302","6483140346a128aad16903e6b143e5c5206b4141c98f6fc5ef9f471b3c18867b","651286d143eeeafc41c8acbff40db27f24292c2752d282199863ff47c3cc62d7","651448ccd04e0b4b158d1ed20dfd85c2579f0c436f7c3cc5d8b609af18f4c0af","65bd57184f15038732c8e9efc3b8d0cd1ee7c8fd3b3fd3ac82096778e5f65b57","65c5f34a3a20d4934272ac64fc48f7791224224c7c0b9166f41b943be8697ad9","65cba732a9daf594b07cbecfb82aca329628e071de78fe9ee75ba31749aa78fe","6644e3a255d8a7d8c29f11374a72543c1543568d8988c2a3f5af5e2afb39fb9a","6680279667ed74d9e12613cd2bdc010b8bbd9bae9f8c81f4dbc34a8887809c16","66bca36005818a923821733cbcdf4a500ba34d96437dd348c4f3d993f2ccc6d9","67ab6f7749215f028f4186fe64438631588ea73eb9bd5fdfbfe25e27f6aec843","67ce8d1637eefd8143fb4db3df551be964cf6fb96aa2a8805efc34bea0a2a979","682c41caef8b0ed27587f3785f356d4fb5c0128fa869c818081f6c8b8cb09a2e","6847fb593cd0c558947ba7d8e2d8199698ec956b6aa7383f601acc96279f7896","68aeeb01e398bdaffe37aa48ca6d34174079426a1f5524d3e3aefcd11191b057","69681d7f19ef0139c71d8a3def71e80bd7d53a0465b5abc26a27562a60f6c353","69889a34d9ca53791a90f499b39e774a4446cd098e583e395853d2c0457c5ba8","6a82f7e8c2285591ccfd9c20ffdbd710f0f5186d1e0334d3b03f639e53f087ac","6a95bd933a3cc9ddae3d4f9c6007468ae9c08e1fdfb285bd1029d7f991e3b480","6aa44eb8225063dac9257125db595db33d52de27a1547cf94165a6ee23d600e6","6ac89d0ee05bb8b102490a0ffdc3ff46744e61ed8131cdaa3a08319592187ae8","6b736abb179612dd878fa029d03fe97e5bff32b8b4c31be9c450e7c938fee86a","6ba84cd8715804071e10bcd8da4f5be5807cef3292a5b1fb1398485223e0274f","6c1108172ff8497f4c76d2ca7cf9705f842599bbf940ee59560b6b229baa6852","6cd96a7cb0d753da32d62c38b0bb9c59e2102300bb3bf7b34f20d1a86abec653","6d51f1e155db4f4f419b2367e56b8eccc141b0d652da40ba2f80663616e8b6bb","6d8e137d325650d6afe45dd7574e8b2573875d0bc976fb4e2fec2d7c1bfbb1f6","6e4c2073ffa7d3555eb794376f03056f5a14ce347c211d5592b2285c5066b334","6e6b02ee11708fc3c64a439f6207c0f24a1fdc3d21196c60be1d8367013e979e","7001a2f9e11c5e5bbc9775f2495351e4dff06412d31d06ad46e080a17248be47","70954a4b30dddf56ba4abbfa56dee64f4ea86d25155c4aa0689a544668b83c2a","7131ae3ba595c77b2ffe1c19ee03df39d0dec387bafc22415c53cad2394080ba","71cded453d6cc8c68ead3c407f5a2bc6d89b8d69f18c199feaa2ca58ec13f802","722886a77f66d261c32c2a40915226698fe6346bfbf1bc94678b78479faae341","7275235f9fc85dfd87765fd89dc7b5f59cd406968d0e0a6ce8891d21d58cef76","727c8d7c240b7a085e132a55b7783e452619eef9a5cf3cac6f38b0217637de1c","72b2c2c8c6197d0e290b9e2a0955f38e1cbb1ec9690361da957af4d1317f81bf","72e462a785c52384f19fb9e4aea7fc94d7026ec09a9773130c6a3da4e6da9757","72ea53ed08159495460b06ba478b6ca18f0d609f71549a9f2d5f39a763272333","7304ac530a81686252a6d72ca470b2ce8d155d46a910428f9642a7f2bb470692","734620ce2eb4679c29b2ce0a7ccbbec0a5bae9594194f379fd9e4e9046c5dd3d","7349349f1b341ceeca6c7ec873a1abc9e5fdfe092e18d949475ac51ae3611ebf","7359dd32bce9eaa245bc425dd90bdcc07540d5ffcbd8133b5b74c19c93ee6b65","736a8cf1eb92fe04eca2efa00219c615f17b7991ab76dde965223b0138973312","74549935b412464bab2947131777c11425791f65070bcae11b1cf433ff3a24d8","74d0a8bc796647565c7114691272c2dea78de265aa34f6bca8de49058c4e8dfb","74dfc2afe6a6fab23ed96a0c12e2a09b41f0afef5a65f28dbcb933297d238b28","74e470c0cd4bd98d9e3a3f163719ef83e15f48d14ee91546f846a3f9f9ae0d04","756cb5d1d44378818c112e3b523206c697fd6a072204ed38ad33dd501b1f90f2","757ef44cb89e0eca0cbb268a96fd42616f9d93a252d495d7844ef9e246c9f421","75c527cade9c75489b23df9112f0a692198b3013de6ca33791d4bbbb5a63ef15","76779eb692ca3307ed6b308545932ecbaf28b987ff83f80c9ff9cef64f0b8f9a","767da3c1da67d9e765d3eae2893798343fdbcb4727e183be659fd606662f486f","767f1d87cccba69a6c7b75ce9db155b124c8117a2c280fa35c0011da1715e618","769246afc55b385730fbd4d3f8bafc40445c5bda6394f665ea1d28a29ef551d2","770190157aeca897d71b524292366ab8f9610ba41e9fce611712f0384d742942","77235f0563f76a3848f259eb34e7fbd599e74eb98cc59b5a7bea9a2790cf91f5","7778203e952f2a7a86990fc7f8cee48992b5fc0092eb6aa34daa321fda17de66","77ca6e343252a18526fc6ef4e7a13291bf0f1c04bc4206031770dce0b23b8f27","77d9bd969cf410ea37060072082cb27f72040387b4d73893523e256d77d9d8b4","782a6257f5bbf47d2eb02a837bf1332581e31adaee38450ad08377710463f474","784ebed6a768512edffbebe41b8929c07ac422048663cda858db2a8dd0785a52","78bc1b655d4132329a0b07228cc216d86d40ba6e270d0ee4a33582d033d0759b","78e2999bcec6630a9b38800925cb4ab0365bfda7f1fd596e96ddcb36c6fb7c1e","79026e209b24167118832ae13db00a5ca82634ab80dcffc0c3ec53eb957a01de","7931be42d1f87c05505cf99df7fc7b6afc7380ddcf04694388e541f63abd4856","794aef692c4f1ec2168a66224c6706841267e5a93ce5d00d41ddfddbd492daea","795b08804867b7e56767ceb59451b83e6cff1cac13e4ada4d05d13b68f623451","799022a0405a4611ea94d6c5672bff8bba016f9fa05018e85e71e14111ab66be","7ab39140aa67d33a10fdb15e03a9c4e388a65842f7d34873345e03283f918005","7ac19aafd943ff3b6009055fda439b0ab77f9ebec95d2dd0cf66fea4d7ed781b","7ac8e0f803ead3fcba77328ebb4278b70e806e83b25fca8b66548f939b80d565","7bda5f72884e09785413196ec61bfe7c4dc9a9d41787992dbbe07a50a3db72b4","7d42a0376d3d57b26d49d030099d862eedbc03a9cbaa119a1bb4d0c508efdae9","7d7b45d3d9fdb3ca521128b73ffc4d164995f437dad7a44f529919155ab6e156","7db8a0fbb87746236e6f264f8ca1b7e4266cbad95b0bdcc143cff3adabdebaa1","7de5a5ee9ca31ab21bdfabce352954d65c0acb10584c2bb1d9de82a4adef52a2","7de783bf1cde11959e4d92f755f4ad5beeea647a97000cfbb55239ed61b0dd02","7e3f4398d80e385beb015adb07d6ef6cf756e17b1afa64957e654866d86e2a8b","7e6c6c188cac1bee498a70b0baf1eef42484abf37cf1ab25c17107d135b80fb7","7e96e9721101f0b3b934d5bb6ee9746c95c47b0b313eb843ebb9751568fc89cb","7eaaa6ab8bff09bbbcfe75ddbfd88993d00f3c2ed7ce4215faa46356b4c38f9b","7f36bbd0e8eee1e4fb2cb1dd03efd84aecec0cfde01c740061b41e974aaef041","7fa05c3af86486ab334825f3752211b337488352d35ceb35406a9c40196bd365","7fa2304c72c689e732d753c0eedef0df8d134ad410d84734f71e15c71d0cc4e1","7fffc9bee78acd60a05018ee8f155c2f383ea03ddea8f74e7a2fca26a43ddc49","2d1fcba7acaf80d772d47f2c6394d165104487800b8b6b6f0a73c4206317d468","217b96333e67ca07509a4552822551af65667e635d0236a195adbc8a948014f2","803337c72bc72aa652d0ad4e989a8294606784a79b00b9d25eef02184e91f51d","80f434fb88152899a33a025561f3b7548425146c90960f459a3e996fee02209a","81332d2ddd039de0840369bc77fbc5f6d1002990571b2d98642cf9dc26a2f837","813ea04db677a89bf6ede3d5f9619317da0a0cbd32ded902822382427f5c01c2","816e739e2bd6f3144d17d89703f7d2312a2ad32423ea69d794191985728c5436","818b6986b31a75505683712ba254cfbdebc6aed762fd5034c1485c8778a8cb32","81ee3699755e1f279e2332e0c06ee699ae8f7bb10250cffa2b55256541cc7478","821fc31a1016ee0e919b2db20591d08288010ca894503d213efdf88fe4715881","82717a7d2fed4ebcf97125f1de2bb1c599122894cd67c87a95201378fa44566e","8285ccc7716777752270195e99853bc33a6c0f364e400d1b554274f460633c6b","8393bd6886998370b8e5d832aeb55eee7e96a004af14811c5d6705451516e23a","83c8b8ce04c624f048ebcc6472034342232af51a455489f221060d42b24f9812","849227c3cf29d9647db22067cb523a57fb9eddffae0c21fe46f320ab54583d0a","84f1ad6fb39d538bffd4a842945c91ac866353ba920b7c87f50139e4580f6772","852aff25bc9a2affd3b486a326834d3333576a79cbf9b71976a3b7ad227535e8","857a225fbdc9bd9a193be0026abd820d2403353d7f59c7a1d4fa193baa419dd4","858c76fc0c722be30e4f70c555a94cfc373a20ba3a6eec1b6ca1ba2f4cfbe4be","85ab637d930ceb590725396d04b35dfa3dbaf21ab6f100bad82bde5a5b8c9ab1","85e7a5f49197c43fa00d52732c64075d1d766aca573e0d7914595512ee1e9617","863f94aa7236f6bcd8091c464653d1de809c878337c5d921dfc0bfbecbc5b43b","865ba3d34c0e0c0807755032f24763260f101faf59684b92f60932afad4db62c","86bf4fb4d2e91b77dc6a9ac679808b7d34bf34f6fef6bb7eab2f5358e86fbd6a","86e0e2ed33bc62e1263bc4eca51e2fa473d32da1d333b3ee57bcffe5bf1f3f4a","86fb0142fce9132e4d944af4ddc39bc5f6c05ead288da2c1f63b06bec171a904","87598b7e9ef617ae80959199850615f85616a8ff7078a4e56360ba6a469d8def","87be113bc35f01ffaa28e7f1582b6cdd9696a5f54d8a83a3a991ded4c7a44027","88bc6505cdf74237a72e6265ecd5031f395aee2fb8238b270030f3f67c6718cd","8917392b01d19524aec67a50bebe0d89277a498f240daef812b14e0b4d362046","891c7838ccbde4a983785bd3d24f4a744c94dbb3e7add7e9e01a17f41d38ecbe","89211bf7a4a2a10a44a58c4252f72267d8ca8a09a3da043510e69d428f5b8183","893eb52b50d880a2f0a1e78677517f8192f9b57fbe3f37a50a847da171ee216e","8970c8527c0b2d04a93756ad7db2bcef7f301654479c4b14c67925e6060be4a0","89dbd4423abd6a056864c1952cc5ec6d3c46dc66816e92ed41f3f6d6184fcac6","89e76a524eebd50fd6d9aa8d4308ab12b198d7a267e8bf9425e6a42981be1701","8b2e781f3c8f690284f112ac7fb288c1b140b07af4c312c401d2e71b7dbfd8d5","8b5c43ffc9a12ac17b437801a6f345d0bd406b21213bd35175553242028fea99","8c43ec29d0f3a41d7285f7124cd591a2cda2da32db8e6788be98eed5ffc82198","8c93df4fb07cc8c12c4bdb6aa87f7e6b54b61dc55033a007b6fc58df4ecb7ef8","8c9a4bac24ecd6026cdae0ee147f4785f98c5b04b6e03403e0c8ec20fdec7787","8ce3fc01834f0d0850e3bda320cd6988e2553bfaeba2da756e12f73ee3ef65e8","8d4afba0ad6d49146aede494833b9852daee48d1421ffa0dbc6bb15677bd6ed9","8d963852aace7a5c830be02bee45e5e360c7234cb006888e4e74a18ac44effc1","8d99ec23b1a3ddb90804303c4b786aae1352a51811ce125604e5c93429b5adc2","8ddb5cdc5208257febf141c02ba93e37dd96507ecfeb53bd7d7676e76da3a1e4","8ebeda57d5dce58f9d18c00b7a117471391dd03e25a509c5dd4a51b5cc2ad3b3","8f717e30bd8a17af50ffa0ac38c8158dfaf71ccc06a75462a56bb4378abbf933","8f97dfa6645586fdc98ed978fbec590671d8bc89d2fd52a47fed0121d6a31fb8","8fa0166bcdb1b7f1de637b88661e8303eeebb023666c8893dfa260afaee9d524","8ff8eeb657b65e834dcc83811104daab261246c5d8fe7a0cd056a4d87acf997c","90adca8034919c62af08f9c587a26bdd0643b03ffccb501b247b79ff30d3a53c","90df9cf1697818b7d08c5e68741065cd977b8ab691ebf4d3efd1ed24ca79265c","90ebae00591db09112774310e5858407d1d3f053f66f56bad99ec8c0851fc335","91e176dcb6f6906f88d7d15a9cca2abeee09d794ab91bdaea70e7fbced4c7cff","91f9e7947fcc6ac3513ff89cdef7b4163bc752c23dd3dcd64e7962f2aa22232e","9268c019d8d739994d4b242818862cb0153ddb407acd0cf6d4d90b83106792d0","9374c095ba58b1dbced3b21cc08d2194cc90194f97a7c6a9d630b8cc7a7232b1","93bf97e46d5a58ca96d908d80f4c3908f1f2e16965d8251fe1fc2303c1533b69","94177171dbdadc31a5172b36534362c558b8c5b71acb1960e75d45764e764acd","941da6fae559c18392da1450df04b676f3fb0951dbaabe205406fa4a182f7ddb","94e02368944dedb539dbde90baaacbb50c0dc19e95ed00e6705f8e9781086c85","950b853e5c40fe3e9e36a5cc570184d8e9a8ec5fbddb74eb3dbd22bbe33b9a41","9580baf2b68aea86e45d407097f099f106dda99bdb66594b4a4bd13548865f06","95a8dbacaf3f2d43a9f2ea70427c6fcafbc571f4c65df5e24e9e7e5cab11307a","9685f912242f5a2c33d0bfabc0c364b4cb3775044ebc20fcf3ac41f492338829","968da59e54bb16c142665a0d8dbfade3d3d236b01343535f273bf9aec9a071c7","9698dd91373c6a9adf7577ffcda35a027e1b25e2af3cd261690f578d851df47d","975ffce75cf0d50b412b282158d069506a229544c8ff2d6ff2e3663379fb1bfe","9779f5f399895e93db56f42c85cf3583aaca072d49b1b3705445929578d663b2","978cfee8389ad2f752305b81554b60c9b6422438493dd9a53f1728d140acbbd9","97abd404adf0e3a731fe20da2c66f24cd45cf5b9d673207b1cc9ee774e8d7137","97b7f57610e98c700983f0d1029beae1f59b69d5f6c2bb3f1cdc729eccadbc07","97d46fc0fbc9641e1b2f5662f69089250faf201b34acf6f3d382ffa8ff1d6cb9","97f26df8e0c788436a6a5cc9b31c3c9931d9aa67886b02e16ec1ed3f1c43a8e2","981ba9a26af45bc4dcb1473c2c1c77d008a7ee8093455f72a533ba114ed21008","9849df8012cc907511eacda454264e29bb0c51b7beda9541dc0307ba7fcc6a30","98a7e55bc69589034da67298549a8c772cb39ec6202c6467c5b1dc68cf1f1488","995a06297db49555d30dd7411f3400a3714bc87fe2bf70022428e46e399f0aa5","995eda45ae132af25b5b20ab74656cac337bcae8c5a612f24fd130c14e853a01","9a3793b95a61645a1b14fc29ec227e042cbf2f59cdf7d491562c786186d1aa5e","9ad99482f529361d0ef7c03c759cda2474b1e171376370ef1a1ac849376c8d87","9ade6f554cc0dcfd403cb0e3eb08e8a616bd5a51ee3c7e1928ab382e34ea1a43","9b19e5f46b9d8fb4ed14d0978fe97248f8a29e32f0edc88598b777b93f59f6fa","9bf2442bb1fa9d6d8dcdfdc4da8d36749b55afb83e5b160970fe67d64e9e915e","9c04517d72bb363ccd5a25669ddc79d23df86f5d9d1f26262e2d522330e32ee1","9c8c1d6a80a639cb2996da5ab81bbb9181908807714d1c8a8cfb70c08453053d","9cef9a8e6f8d653a2372e03fc07094589ee817a345bbff9b0db06daafb9e546b","9d281bda01f37e9e4c370a25f30fee0ea6fdd9c4c4664872090a8a793e95e5dc","9d5efcb80575401c218b28d4cad8c423b1b7f46ff290288881c44388b6f4d49b","9e0a65e8e39cbc7cf934abd710f4f9e305eefa7cf10b78dcee35a1bfc9e0db56","9e6edf83306f075298e0a361f36e114f89f8763f694a980b3d2b0425ad7a2041","9e7f129913e23b7e73e478bbb03e3600a2fd3a0484b5af4eb292afa6b2e122db","9f3d4cc66a8ec174342a5fd969a4f8149e22426e7c818ba09a13e2a7d2afb912","9f7e89810971d7bb242e6482330d0488ba8943af7393c4a976027b57c4d9186a","9fe572a28636f0283ebce2cc9674ce5b69dc2de6120a34182271381e984b0b66","a0b1172630d7b1dbc105b41c2a211144c57179f92275aadbdc367ba9eb80141d","a0d8a49e8c761062797737d78cff7dd5d0868b2b97bf33e171df7fe3566eefdd","a17fec45df36c7cc45a13a2754e2ab7c7a35a179f1511d44b30753646de69959","a1a17727d712681557e99c5d4dfbfcb37ddd6654a57e04a6c157b9ca2b001dfe","a22b0fbbb2b6324a0bae51bf7db9936234fc50ee417db50d45e95f9871530991","a3180eba69fd08488cbad05c12e831bde6d3a5734d8cb2589e30b051c601f684","a39f8f79b11d01b4c8852542ed8b37fe6ad8588f4ba0b0d852084f7d769af37a","a3a09d9af720f05b17c512ca22677a67821af8b1d88f4b85cce2621c84c37384","a3c3e51da1f347966b407f0804a6f71f66210967d2bd4b32084931dcaa475e11","a4c5324c3889b87255921547f49df006c10bcef4df9d871a3067bf4a9216f11b","a50fddad620f947c8de64e00cfd2f4e40b10df0bc861cfe3629ffb901c091ff2","a555c4f1e300d5b8b8275c29ff9a8e06f746ed736edef52ecf2debf65f065e36","a58ff3213623e5eed98aab69da852b81ef6396ccdb934c110c9d31b9a9203d3e","a621e66b8899b8791fb55a542c56ec85feb38f31a2bd880c9c05ed573f3a7be6","a627a9832b8cd82a00c7fbeb6b304ae0b871073ddd93a544ed5a61a9f91cfc75","a652a7a396f2905e5240f673f7c34b87975642ff4a731a27bb460f4dbb3977ef","a6590d9cd47734d68e254e1502441ef335476ddf9538a97e8be38848aec1e179","a68114e5f9afd127d933fe55db998e839652bfa82502328006ae8403633d5a3b","a6e7afe4aab654580dddcc01d6a4c3f31350195dfd60505ae7a907de7464ed4b","a6ee5f3a80daa76ddb699704d8aa7bc00ebcc93d3db760d6e326c32c486e92f8","a7013734720135ee5e921a555e8fa3b31e841f2be40f1a704ea38cc8c04ba210","a79b123f7a7a6f1b4d3fc41d7ac0b5a3fed7f70cb78c4880fa201ec616caaa47","a883f5dd28e2a991551cd460f61ba45a8a64d9da8fe7094e90d1ae70c1c66ec4","a8df590c89056776b39209ea8fdb46466a658c73d826f6f62dd43c53ffeb90b8","a91a574b1811621ce9904f50384803ef7149db1405802bf2ba92e105cdabdba0","a93b6d02766a4ae335373e5b3ebff076e969db8cfd7a5d6015fb8db1f77d21bf","a983c04f46759f4ba79ce3d26b5f80150ba14a1d358cf86fe3c7e33efbdd3180","a9cad301e8adb9d41992dc05bf2a2d19da5c48b003cd4e5434f5438d9427de90","ab00e0a83188025f0feb4768f989ad7333cc3ee0303d76322bceb9a8b6da18fc","ab2f0ec0019d76e35188ae55782491ea09ec4844e51aba01f10afe8d89520583","ab7c54ec152aaa30506cf165483261292621fe941da8eb1e2a871b0c854df967","ab8f4f9e1c720e220693d6a60274fbc50858b53a33b85014821a7c810e24fad4","abd4198586558def2710f7e4bc4945455e2a6bdb92b47b091b38ecdd1f9a0b5d","ac9eb89322f48f73411b429259e98f6c7c64811d4c4c0529491fce93ddf4addb","ad97d99b09b3f0c3bc8fa7f2ed74fcc82614064360a09b28601ae3798fe81291","adf37be915462b33c162466327fe1064e42c948a444fb98eae47ed677cc5f927","ae368c65908ba0ca071870194cd55723a6b6ed751a95b0e714e2465e9ff70324","ae8b25ecc42cc81521106f0c2eb07cd3b5f51f4b1d17c625b2f6e439b7f72521","af0875ee2e62a55b2dd39901384c2b755aa9f1a12f09e2f616630171446497f8","af67eec823604768490b87095d3dcb3f8e8e5f218527576183621e3113dfe850","afb264de8057a9ba7f79a51c80f99354004e686bb650172032aada5126e7f014","b047bde1ea216a82f57dbdfcbaa363596e34490774eb45c60fd342e88b59e3c9","b092c864faa50648b87dbb3ee868a792700e8b0dd19e45607d29133335d842f1","b0fc83e5b41ee69fe218e110c5d70e2db2bb8e7c2080a75981ab1acea3757232","b1152384ef207712896ecdff4ce29479015999c7cfb6cc38614fc21def13230b","b135aa2a24d99f8341222fdd8860214812750a9e2d2f271144ef3c68078f1a71","b15eb55607e28af724d795a6e15004036632121247382c6146827f486c3433be","b1f6d48a2041a3afbef0fb55f19b447a0ba4bc4fecf5f53784022c0fe2f7bfae","b219a4c1ea372beededaeaab08a9244f7c701cab3f571457495d609dbb78a1a2","b22daa0ceab303c4dcca1b1fd07d272e61b60b47f09f32c576d42ffeb6fc23cf","b29cd4d04222506dcb7a394e12b1666b0f120e10c23ca16ac5ee3a6ddb38da5b","b2d01b8f8d29397bb3993b46161de9d8054b290646f50eb60a594f81708be39b","b2f41364028bf0b5f3694e500fae1d0e0ba9204e08c6e39e7d7f5480345aa400","b392bad323d291719a854fe4199ec7a877cb125ee7cf9d0fe8e350e4bb326b92","b39a0203d8dc6a1b34bc4887d6eaf47ebecf5960536f045a783b99b5028e3c0b","b3a544340a55a4b34088956a103b7fd14970c32b60dc3c63402c131ea2d36a57","b40244a9080912f3135ad06fe4b9894903dc732502f91c99572775e997eab940","b41a4017a4972b875fe1b4b85e51ab10655719d06ee20712e2d4b1533a0e2892","b42966abb0a643045fbc1ca144b020e2193b808a59ed0326a501eeca06795f3c","b4a624171a008a594a1615fe3c53d36871c188b1d9ec3a0ce5272bb66f85d222","b4aa2500290d3e5733b2ca925129c886308d2a0934bdfe3d984fcc10c9772dd9","b4c9257239d54f35b48975698083aa495100fa5db3092a2f62a3ebe1cfbfb578","b5e3dc1b2cb8a75bcaa9b160286f56e7b31b5805c083cc6042412f9e80cb9e19","b666dd47abfe656cf03fd9605cc25f7c2af4e2a45d72fb5024fb4945e4f2c7ff","b6744d80662bfc71306d0bb16d0b5755b30b12342922f63cbe89f8805f866e86","b6db92c5758e53620a0fff652f1506926dda86f586872f51fe848794885a61f3","b70932e1b7a06b3e164527a0b6e0eec7118b8ec4a10833de54b2de2f2feb5cbc","b73a0b9f672b670436f53a46e7bc4ef6f3cbc3ca1819247e66a6fd63c77ff347","b775bca11d1dcbd6987d69d338170eaf195ab246ebc903348003fa1b7d45af73","b779dc6ca6162db3643fc673fb36c8b2f1e8ec93ccfb866c769a1c7f5fcec41c","b799df46e6c587548d675f9d726050a62f00cead12c0559cdc8fffd57430c343","b8ff5ebbe2402e127c5a1976fd53f750b61434a23731539c99bafc6f05ce49ce","b9371a861e160df9820484f478bc2906f3fea4f0df0b168274eca93d92f681c8","b9f9e8ca1d748c8b5319275572cb6ba17e6ca46a75d1c01317316cfb9968f159","ba269dc70371d4cc156a316204bbebd7cd0b6238bd08ce1ab4fad39852b33429","ba5b5fea67dc543c9567c9a30744686014af26fa28ae3bcdbdd2af092deaa8cc","ba88258d4b92a041c5dec03e9654c92c3f58213fef6451d70d9b55f664e55ad0","bb325fc53e6319bc82f7c19d95d14c70b05b81177ed39d1078741e8954a76275","bb96318fd4a6579496b8ace2fd9b19dd4b3a9a554269c7f5d9a20c9945c7bc90","bbb49acb28a9f0693d5f300ca3c03228ce49d59a0a1fda88e0b6fcb5ffc0dd83","bc004396aa69c9b7638d193ddbd8d63818ca3660ffe9a5d469fc136b30675c4b","bcd962df08031c5338d97519f989e43c99dd54817201feb1da88f0512ee0f6aa","bd16fafa6c3f0fadb1a70829593cac272ed4af3fce1dc25fa131f6f715a4a122","bd1de000a35343c08c4252c51b3a21003aa78dd531f777bf4ca3834b85973b7c","bd29deb992f2107e990ea2621adb6c619ac495ec0739ae61370b0c6e04c29678","bd91a9e4380758c4e6c89564a74fb584abf358fe1335a8a6abb4d80505c55611","be1b45391803b2c966a4798c43f7b06349a6f33de79f4d874997fd3f88b8688a","be90b489951e09026c0823b0ddb65e23b9803bdb37f486a8e2b5608dc21af84a","bf386b94c91d5efa0c97c96d020a63787c255252e42c539aaea649892e7bd19b","bf4db6d43a343b6c6080a34d28c2147ad1b2ed308b3ad8d342fb43f50456f37d","bfbecb24d37e8beaed52284d74271722f4a92eb4476c5400e09d9d0f665b2fe9","bfe89d86ad4332363524a8b0e4bebb5f52403aa1814ea807bd4602443737a456","c0215ae8cbef32e82a45660afc6287554be92a460622d033270ec08776b35802","c10aa29b6576a3cba5ef401a07fc595ddeb67e8d5f9f62cd8264b8fb1305aa1b","c1241a19d61cf8d63aade78accb0b2cc25ba8530f863421d310b44d284a97af6","c18c595c073a3a09479602172df9ae835820618a2b8d39eea348d54114c1ff42","c1b03c6bb52207020ee33f9efb1609074d79af5bc913aab4fc5df3a081ecd2ad","c1edbf80347e16963a362bb2a1e9fb323b6f5af8e5407a1730a7989270e3a4c7","c234c2dfca43e90bcd3b3e5b00c78b8b6aba9e5723e99e1fd0fa443c598208d1","c3125b8208a46cc054831119386d71345f97e2f850b466a233422862b3d2dd62","c31694758294c8f890f37fe86c4250712162cff517c00b2cbfa69eb1529448c8","c39565e0dd3eff00a4c9c07a488b3ab392883bb1d7be994ef5d5ba3ca786eade","c4a0400eea305100cd10afd586ceb478d79241f76abb6b97bc4da5c543bfb98c","c51c06a2293e87649785ca69cf3f43a3f2c59e8e1657ccfeb5e94c59a9ea033b","c56ea5600b5e6cd7c6a5fd249b9ffa3ede3511abedc13ecb6b858e9c362ede76","c60b9a71620abbf10f2e8733b03bd70af49ebcb385052dff8a70adf8759d52c1","c61731f14da974b101350fe1a4f89ea5f9c2fa488cdb106186aa20785e110e76","c617906d1ba9f62d1e7af0e613920ecf6252468a7598dd56f340a0b7b6e5c733","c73347fc0390869bbf5f5401a4e44c23d9005863fc5403efcae92fc52be93032","c73c0c281441b7a826e5369c97b4471b8a97611d49d717fee4f1617e9db1676d","c75fe787358afb58a91da76436fec66f97ca6fde4d471c5ff189e620908eb704","c76fbca3e1df022151cb1b5950f9f7cba868fd8c7a95b6c7047b04d532f18a12","c789a8fa7c5f9f2571a5d7345208d0e89619b1a24a351c3cd57f47d51bd2e41c","c7dbe768206eda376beaf98af5b32f6ad88e1395ddbb568c0be2f28cc9a8af27","c7f3769200ffb36c33f1182fb8523ca47d047cf7023a446ef987c55ebd40d428","c7f6168af37e219395a3c57cb85ad45530019a0162d0780a59f782f2e3e3112c","c80c7f450e49030b89df770ff7c22d9468da29be7c02919e0d5827ffb690dfd8","c8e0056f4c1d1442c906e5468490bbae2b3c13c46ff9bf4f7d697e7dc4dfab75","c93d78be3d7c20dd292340834458a4f0ccc1e266faf4bb79302e2a1ec99a011e","c9cadd10d8e8066cd2fe730532597e8bd46d26df695565a57a72da51afc56b7f","ca1b48adea564ed42bd447977dfcdd60f0495c5f3a7fdfb19618ccd4051aa4e8","cab73cb62aeedcb8fbf39db7017b73063c58153b336365060344e2cf532f7570","cb233652d31b78603f79f6b90ea65d6d217fdafb462aeaf9de12a3958b8dd1e9","ccd3c64d6b1341488e71de5a03c83b31e56800c675fb05d6a4d1fcac73d0eef2","cd62132f8dc8bd8a364582c4b4967175c1ebd2e0253e9e715117df92432cbdee","cd7a8bf44c88dd512baf4e29274715a6dbc27850396fabe584ac0dd37890d519","cda27e7cf67394d383227913a7ebd1d7a39357d9d10500c6633c69f450b0f4ce","cdfa963165efc6a0a60bf54b951bcbbb37257ccf28df33324988d4fcd11ff156","cead03041229e5299dd0db9a14f80dc32536bd94139668fc85fee3edaa184880","cf258291eec169f680646121f0a1060a84197930910aac74a84db573ee17303f","cf7e1c65b5ba50f06340c98c59b2db3ad3150d1c800e493355cfc05d3454fb2e","d24e01491766b6fe9ff78860af3642df3e80748a0db6fcd843d1022dce274fc2","d264b528cc9d77882c9afbae0022a378c2d21a805cf4cc94588464a9d1e26f2e","d34da08f76ec02085f33c2efae50b536fedcf4096c4a4747be2b751cef236882","d34dda83aba02e0c3094afda737e177b9d82a68b98b1a4bd5f072039a58cea87","d361dc22f05bea4f5b05dafd7acd10eefecb5dfbebf7117f551e394cf9572bab","d3bd873c05cd9b131b4607e05f27382cfe1a327eda974ffdbcaf6d19d2aec23c","d4218dee07deeb1e9cdd465aa31dd32fca2d6efe57bfd891c47c03ded60961a1","d4592cebd312f2afe208fa8f008e05e3da7669b1fc85a73815d1e0e8dd54aa4d","d45b978c00a8acca7e602d8ddb806b3c85936219b075ca133575f529b2fcb8d4","d472d2e584c45410f5726639b23af36d09169debf321be706fc38202603947a3","d4c2576ca10c551db9ec8b9dced586565c441657e546ff3176383ebaa2bcc771","d55e56c6cf896ddbfd2b33d06f9a3fcf4e48f0c184aac990f723a111361b16e8","d5d9eab7fa308f90d45c12faf27b8faf50253f82b95cfd4edbcb63da67289667","d5f1ebee8891a3c8839dab42cc49f97a484af16423ea262ce151023a41f30c3c","d5fede2c54460559ba8a671de50c5d10f46eb59afca7a0626a839638401ae800","d6862148a487432fddd4ae99b3cef0899e40ff8118f8c0698d8b3cce6a6dfe4b","d83bbb01c80d1a387ea099fcb0468b3ab46c0777723f3bcfa27350f301994274","d877c19bc0bf1bbe76f19da30eb1cc58646f6d055f73331d5678f6a1705466e9","d8b23223674cfd3637a0da61af0efdb0156e33b90dba34ac6d5190c68b172fed","d8c17d3507ac742150592a6d249f4bc052bae15e9ba6d4d986c8fb1e8aa7b582","d91ab7af69c949637dc8901e3ef6105bd6481b67799e40090b9108eb2e5b55e8","d987cae1a87051c9aa04ec9d7800960dd74179d98d9c6fc1ad80bf39a38ffd03","d98af2877a1e6ed38fdba88832b9533f0a08fcc8a9d85eeb570b252740ba523e","d9b690ed94bd83fb5459d03f711bbb363b4079b4b9b254409d7a9ffeca625660","d9bd89f58e8f17cda5ea2f8c441518962bfbaceb3cf1e585e898f59dfe00bbe2","d9c4a6081d8433106c2413ef88b637660097a58d39e1a9ad047253b21524bd67","d9c887c17e67fee7fe16dd8899a4ab3f701a13a049d40f51506b1848b7776da6","d9edcde804f13a5e3b03bc70987185af240522935e6be1e1acedd7398f8f4f1d","da24f12adb47c0dbb6c60ee3c4d6c58a65e7d3ca436d90610dd74eb51329b184","da543645e52fec60adb6d21a90c68e82f873b0bad898fd1d8bdcfd22260b62c4","daafbd50b17c93c2b2ac5d1095a3556b72dee4e2f08de2c7aae36673648b96a1","dab9fd9fdf09d1f39de28d438508a4fa72ed075c2242cc74c277daa690038930","db67151d1e4b81655654310891330047c9d497be2d5c6856a5aad101db4c1281","dc6eeb17b582df008af5cf5fa03e1555ac9da973b679cfa7265d9957a4c3bbd1","dc7cf7c42fb85e08eb9d60c513dc631810f8b76081e2e60e97caaf86ee715184","dd0f0cd62b9dd337490d8146007d1d1460d2d86390e876dac2a50f4f00eff9bb","dd26edc25ec6cd9fe24a87743785effbf816fa6e0de24a50665d30198942fde9","dd6ed84fce2a462db528a5f4ec91269156346ad14beb90786b541cdc61e84503","dd75bb08e47779557d21de0c9edc52d7153d5b035a83bf31127c916db75057e3","dde4fd44fba344e07f7df236175d40d0022a096e31d8b0e927e803ef3c41f187","de0ac67555937178a8bd8559c99780b19732b420a6a8b5bc05a032c1238c4caa","deb3134b0393f0e17d3bb705be2eb4261dfc94763663eef2c66ce7116b77bc9f","deef5933a3daaace77adde1b2cc602af9690cf7af517849fa9c4edcfcc0a8a73","def89a505c18fa12af885484780f94fd0bdedb99063470eafdbc2001965737d6","df5afb82dddb6eb4b9373912ee09f6e1d55784c11eb0322c82a1192c93aceb14","dfc4c3d01dbf34c8e7bb2fb74eeafbaf3893a14e2f2b6374de397b920da4950e","e0017d574358ce0ada84666ebc6966b567d628abced954996deaad978d0974f1","e04612d221c25966a34f08a519021ea462aa983194d6af7a14d26b5af70c2651","e05d8c53aed144236715690d21dbe86cd6013151fa4742bbc51eba3eeb55da70","e09c8d5ad3bc4c94546df0124ca26ad1439ed05dba322389fe3b222bcfff3136","e14e87dd4cf40cf4301bf05a7a1feb3e0a81dfc2f4133865a8b949dc034c3a85","e26227be2d741d579fddd763568c53a11c1ca3c2bfe9422cb08b03f819be6883","e27905be7022d18ecc98fb3d98dc905353a8048277fd56586e9509ca20d84eb1","e288e0c7743f81bb279b0fae5575588700e0245b51091e13b808887b34e0737c","e2a3dfb2d3bf435d927e0c8105a8fd89b33ee6e4678c212b8aa2dddc166c9e4d","e3d657de148f4733ead690c4e06bf8a3c3e6514f7099a0cc64142b99eb64ea57","e40405c14335b97b1aad543fc616427cc3422acd7073aa4c6d4d1b5683da32a1","e43bbb8c573d519daf6aa73028ef5bd92e87c740944d1bf39a4188b176cd2151","e455dd46924fe7385913f139087cbb0def1d0e32fd82de77a48e70f8714b0545","e49068d43539e70c70ce68457e1e786e1b6f03389bb53e7898f478b5a6a0f6a7","e4e3a145bfcaae7fc00a4153e7e67c7c252c1a804e717f8cbfa00d83a7e7e0a2","e4ec4c3bcb33b818d5c4212ff2a4bcb97a9dea368f43aa8189adae2e0a47f3b3","e50d5e8a11611cfc44e2b286bab7b9294ef7e52bdd4d941b81b8167a8ea62922","e5c4f8163c543ae03111d7c7cb3942e0fbf171679a9f1c4945675d11bf7068ab","e5c8dc40979a1c9f8ccfee1cafeca464e12bae9302d39cc62fafdb0def17ce58","e5f5fabcc4101cdd4a3e9e74b6ad974a3a7cfe82aaa8d7a5b1a60f9bfd725947","e6060dd0e13248951b861e6fac90e049f3045b0adfd29083b34a8b1510121108","e75001b78170959550e7943ff987163f9dc164bd88626855abba578befe08fd2","E794c186ef0b509bc202ca69233275bb6e35b218fb01c8a8cb2d3614c16eab93","e7daca6545c6902ee809839a2523da9b7ca199f2f8a00aaa932614e19bc4c8d8","e7efdb6344c5693edf34ec417c65d2c0c3d85d224efaf4b51c89519a43649ec6","e80186b8cee2239ec9e23c8a7af28f697b1f0b69065cf7c8c197502816bd8fbd","e82f0707976b33b8f2ad1a5daeea46895c625161e87c5269bf2a9fe0654ca369","e8b67f26bcdc2dbfe33a9b7bcdd22e2269b5d970cfa64a271b3d978e286e0749","e93002672145a7694708c2da2a8cd3924a9520c513da744c2507cac2ce14c927","e9a13ed1767da2d2735163d10e7e0ca6efef590a045ddb86fdea8856d20d9fcc","e9c9f5c581fe1440aed68dfa70b79db8ee7632e5c6d872b32e185e4256232c9a","e9e0ad8559e90289d7cd366a7a07a519686457a6f779b11e73c56cbb4eb82072","ea48d8a0f833588558f2f9530b33a600399f4c1abdba8e84d968c4d97a2199ec","eaa102c98daa3536854657907e12de6c469d6f2d93320a3d7e90a59bb9d70595","eacc0163382f08988f9fd293b3aaf3c7e057be5f3aec8ed35810ad8dc2c0afac","eba472eec1b2e95d69d560620ecd15fd5a57f7d231c1c3bc1f780d8a7faeb82b","ebad02d6602b5a8ef16f60d974c7822016ad9b843266760a0fd79214b160fa22","ec2cff26c627cc631faa387841081f8a5ec78baa8e594336a2c735cccefe9c78","ed1aabd2dedf34c29bd059166a153250071cbd7b2b47b182aa3b26f1be173b90","ed240c9853d9d3314f7a0a71a165722ac1f72e3d5450034d89543462316a4e52","ed817a1e117bb940e559511add3614958888fe5bf96a7cd5dd9ed2bcc53ea242","edd79de62be83a1d86b0aa99939d11d9f2c19b91e36532f51824a6891ccc2772","ee23c3837d4c94db8b7ae3d26983a0bff0bd89341f1a1bb19ee7d21057eb81e7","ee3b8acda535268d9f1595cc4c80cb517d1d9547d4e7c8d828db29957d3b4b8e","ee5060b689e579d73d50e3be48d1b9097b4e5498fa457a469657ad99fd8b8f93","ee5154288dcb91d9c879d267d034c68139bc8e10a3201a1e46060df015da6ec1","eebe10f1d3460e2e183b64fa50ba50f7903bb8ca05030b3ad825283c31931f3d","eede73e774f08188dccf33a6bc248749ab30d898414923b328864f44c0cb254f","eedf2f47155a9803f539d40579b863c95b4b51c755d6bac54269fad27ec4801c","eee49f288b18a6c57db1ce60d80b58b0b7f69f95a3be9f503afa85c166c01bdc","ef189c37ddcd24eebfe9965ddd7f444c03d2747964ecb97eaebd15cd05381c99","ef4074a0524da7e478ca2700bb9e9ba3a6877b0a8083a913c4c76bbf5bf6dfc9","ef68b48e3ebdf8be93df108e9de1fa68c6455edec74ea3c8d0f6283382c0e4e9","ef73650d04258cd780c3bcfa892ac72b2184fd2badf7c0c6a0046e9ecaae5ae7","ef902a834f53009c8c0469d3119c4347774d71bf049258c7de3fb33edc0df2a4","eff259c0441b0258420b618e58a789d3a158573e1a322ccb2f847c94cefc2cc6","f028ef084f00db8bd7f0539ff5b41abc80f0c1ac587b4fdb449e8df2271eb411","f1919b029dd000410510bedf6a78c31f3d2057002eb99bf8f3d49d56ad2540e1","f1a53e9265c63b3d05cc7cdcd01262cd4cad5adf4b0047e4d4377c7f8c3a5a85","f1d60ed2ac8720cfd53f3d32da2e765ae76d1948ff7edb2eff056d81570eba74","f2e23e8c97ed09b78b250e0be88e6664fdf98036a04eb52108eea11611ee36a8","f347eaf1c83aed8aab85779d9f7f69dab0bb01a2f0203ce32908a84b307ec9f6","f397e51dfa55eef4b157e1f13a824f3dab99ff36ab2717e42572ca83b76a2eb7","f40d80f1f24fff6f89275d02eae1624bc832a8338c737fe66d5ae192d84c68b0","f49b220555da550990adfc69d0069868a57e3ed960a25ab43c1f598a7d70b420","f5966a0ec93e7cb196c9be71ff324d7e93312b7de3ccc29c70540171d4b788d6","f5cbb8569e84e291829cce2437ba1c93a6e078490b74ae80198a81dd73028869","f6344c3bceb57d158c2931a75b977f95dd09114288e58619ac193c05860b1d5a","f6d43b31ced8892daa482725f8fd1ae672353de1282c5b033baae2713fadb24a","f73c0af4442c180820b7cd15c310072774a7371ea0d04fb31be73c9784181dba","f76238f994e086ab5c4fae8d63c9366285d7aac938e7b491fa500ff834144510","f771bff3e411c13f5fad663330f0f6ca63e72f945fd879d74fb860c84835a00c","f813baf8822b28b339bcfa298f78cc787ac8bbd5b8d8c1c65af211a01c3c1245","f82129be820775d87542ef184187382094ec1d97f934e3fc281ff90de44b05fc","f859a28b9a145aa220a663a3651781b11e6cb0eb91dea4102898a691797d6e02","f8654fd81fa76e594c6c80c9cd05bf5b5f0f71a3c1174cb3baf39ef8401a3483","f8bf74340738f418b802899c269c0313da223ec8752eb6c0e64e82eff174acee","f8df3c500c0b261296637dfde60e91709b2519e354cd715f3ab1cc6846306c59","fa81d0f67385b9eebc40e3e8f11cd493238a20fcdace7d8925238044fa654902","fa8efd699b2028670edafec56519f9f21dae259731227cbfd81d14ad40326a3e","fac39f24ac6b44ca1094db3d5a3826db83c2bf610e9f1bfe9b56be3df175b289","fac8db6df759ba08c860862593bd2a0b92b5ebda803337d2248f0c0b874f5e5c","fb7bd969b6d219c878920d4cc1ca54fb4222aba35988b541114c1b97b948524a","fba9eab4830125969548076b8cd9ee85d6416e305eee3ebc1993cb84bcccf14f","fbbe2d2612db5103b5d47fc24e557d709ae34360532b4c358b4c65584522173e","fc79aad737a78a2efc52b2debd1bbfb24d3ccfc3c239a8c4e41b4d016b5f6531","fca5c1cd10067cd974370cf61ef0b4855346f7b371d445925aa39a8df17a0e9d","fd08bda7f4aa744c2aca01f0f5c10713d326a1cad227f3a555e38e0802ec8190","fd2452c45d6c6065ffd5430df6e2784db8e61e967ae9b12a7716d037838323bb","fd4aaf22852f8a938350963fcbf656341eb044b4f84a04cf92d90a8c1a74ba46","fdab27844b32357777a88c87e6bbc0ef8bca9e5ba4b400decb9c889f267de28d","fdcf99b2cdc658ea1f4af388c7ba3d8a54483f7ca06b380b333f6f12071df581","fe1178d34fe90705241fc39f548ad56eaf90b77adff9c94bc926fbeea15f67a0","fe3cf05b864d8b9cbe306257e4c6499891e903f516f6dce72852926f094f9f02","ffcc8b2f5b089e9be88599ebe68a8ac27223e5aa0273a1904103646a19807bc6"];
  };
  if (hasBeenInitiated == false) {
    _init();
    hasBeenInitiated := true;
  };
}