import AID "../motoko/util/AccountIdentifier";
import AIT "../motoko/util/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Core "../motoko/ext/Core";
import Cycles "mo:base/ExperimentalCycles";
import Dwarves "../motoko/extentions/dwarvesDid";
import ExtCore "../motoko/extentions/eGoldDid";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hex "../motoko/util/Hex";
import ICDid "../motoko/extentions/ICDid";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Bool";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TokenIdentifier "mo:encoding/Hex";
import Weapons "../motoko/extentions/weaponsDid";
import _characters "mo:encoding/Hex";
import _stake "mo:base/TrieSet";
import _stakeState "mo:base/Array";
import backup "../motoko/extentions/backupDid";
import eAdit "../motoko/extentions/eAditDid";
import eCoal "../motoko/extentions/eCoalDid";
import eGold "../motoko/extentions/eGoldDid";
import eOre "../motoko/extentions/eOreDid";
import lgs "../motoko/extentions/LGSDid";
import leather "../motoko/extentions/leatherDid";
import eBronze "../motoko/extentions/eBronzeDid";
import Nft "../motoko/extentions/nftDid";
import icrcDid "../motoko/extentions/icrcDid";
import TokenCanister "../motoko/extentions/tokenCanisterDid";


actor class EimoladKernel() = this {

  // IC Wallet
    public shared(msg) func account_balance_ic(account : ICDid.AccountBalanceArgs) : async ICDid.Tokens {
        return await ICDid.ICCanister.account_balance(account);
    };

    public shared func this_balance_ic() : async ICDid.Tokens {
      let acc : ICDid.AccountBalanceArgs = {account = Hex.decode(AID.fromPrincipal(Principal.fromActor(this), ?AID.SUBACCOUNT_ZERO));};
        return await account_balance_ic(acc);
    };

  //==============================================================================

  // eGOLD Wallet
    public shared(msg) func account_balance_eGold(account : eGold.BalanceRequest) : async eGold.BalanceResponse {
        return await eGold.eGoldCanister.balance(account);
    };

    public shared func this_balance_eGold() : async eGold.BalanceResponse {
      let usr : eGold.User = #principal(Principal.fromActor(this));
      return await eGold.eGoldCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_eGold(tr : eGold.TransferRequest) : async eGold.TransferResponse {
      return await eGold.eGoldCanister.transfer(tr); 
    };


  //==============================================================================

  //==============================================================================

  // eCoal Wallet
    public shared(msg) func account_balance_eCoal(account : eCoal.BalanceRequest) : async eCoal.BalanceResponse {
        return await eCoal.eCoalCanister.balance(account);
    };

    public shared func this_balance_eCoal() : async eCoal.BalanceResponse {
      let usr : eCoal.User = #principal(Principal.fromActor(this));
      return await eCoal.eCoalCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_eCoal(tr : eCoal.TransferRequest) : async eCoal.TransferResponse {
      return await eCoal.eCoalCanister.transfer(tr); 
    };

  //==============================================================================

  // eOre Wallet
    public shared(msg) func account_balance_eOre(account : eOre.BalanceRequest) : async eOre.BalanceResponse {
        return await eOre.eOreCanister.balance(account);
    };

    public shared func this_balance_eOre() : async eOre.BalanceResponse {
      let usr : eOre.User = #principal(Principal.fromActor(this));
      return await eOre.eOreCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_eOre(tr : eOre.TransferRequest) : async eOre.TransferResponse {
      return await eOre.eOreCanister.transfer(tr); 
    };

  //==============================================================================

  // eAdit Wallet
    public shared(msg) func account_balance_Adit(account : eAdit.BalanceRequest) : async eAdit.BalanceResponse {
        return await eAdit.eAditCanister.balance(account);
    };

    public shared func this_balance_eAdit() : async eAdit.BalanceResponse {
      let usr : eAdit.User = #principal(Principal.fromActor(this));
      return await eAdit.eAditCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_eAdit(tr : eAdit.TransferRequest) : async eAdit.TransferResponse {
      return await eAdit.eAditCanister.transfer(tr); 
    };

  //==============================================================================

  // LGS Wallet
    public shared(msg) func account_balance_lgs(account : lgs.BalanceRequest) : async lgs.BalanceResponse {
        return await lgs.lgsCanister.balance(account);
    };

    public shared func this_balance_lgs() : async lgs.BalanceResponse {
      let usr : lgs.User = #principal(Principal.fromActor(this));
      return await lgs.lgsCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_lgs(tr : lgs.TransferRequest) : async lgs.TransferResponse {
      return await lgs.lgsCanister.transfer(tr); 
    };

  //==============================================================================

   // leather Wallet
    public shared(msg) func account_balance_leather(account : leather.BalanceRequest) : async leather.BalanceResponse {
        return await leather.leatherCanister.balance(account);
    };

    public shared func this_balance_leather() : async leather.BalanceResponse {
      let usr : leather.User = #principal(Principal.fromActor(this));
      return await leather.leatherCanister.balance({ token = ""; user = usr;});
    };

    public shared(msg) func transfer_leather(tr : leather.TransferRequest) : async leather.TransferResponse {
      return await leather.leatherCanister.transfer(tr); 
    };

  //==============================================================================

  //==============================================================================

   // eBronze Wallet
    public shared(msg) func account_balance_eBronze(account : eBronze.User) : async eBronze.Balance {
        return await eBronze.eBronzeCanister.eimolad_balance(account);
    };

    public shared func this_balance_eBronze() : async eBronze.Balance {
      let usr : eBronze.User = #principal({owner = Principal.fromActor(this);subaccount = null});
      return await eBronze.eBronzeCanister.eimolad_balance(usr);
    };

    public shared(msg) func transfer_eBronze(tr : eBronze.Eimolad_ICRC1_Transfer) : async eBronze.TransferResult {
      return await eBronze.eBronzeCanister.eimolad_icrc1_transfer(tr); 
    };

  //==============================================================================
  // Work functions
  type Time = Time.Time;
  type TokenIdentifier = Text;
  type TokenIdentifier__1 = Text;
  type AccountIdentifier = Text;
  type CanisterIdentifier = Text;
  type TokenState = Text; //None, Listed, Wraped
  type Rases = Text; //dwarves, humans, elfs, orcs
  type Rank = Text; // Ordinary, Lieutenaut, Captain, Major, L.Colonel, Colonel, General, Marshal
  type RankValue = Nat;
  type RarityRate = Float;

  type Weapons = {
    weaponType: Text; //one-handed, two-handed, bow, staff, 
    modelCanister: CanisterIdentifier;
    ledgerCanister: CanisterIdentifier;
    state: TokenState; //замена статуса на стейк 
  };

  type CurrentEquipment = [Nat8]; // []

  type CharactersMetadata = {
    rase : Rases;
    modelCanister : CanisterIdentifier;
    ledgerCanister : CanisterIdentifier;
    position : [Float]; // X, Y, Z
    state : TokenState;//замена статуса на стейк 
    weapon : ?Weapons; 
    equipment : CurrentEquipment;
    rarityRate : RarityRate;
  };

  type SCharacter = {
    tid : TokenIdentifier;
    index : Nat32;
    canister : CanisterIdentifier;
  };

  type SWeapon = {
    tid : TokenIdentifier;
    index : Nat32;
    canister : CanisterIdentifier;
  };

  type Stake = {
    character : SCharacter;
    weapon : SWeapon;
    aid: AccountIdentifier;
    startStaketime: Time;
    lastClaimTime: Time;
    eGold_amount: Nat;
    rarityRate: Nat;
    rank : RankValue;
  };

    type StakeCoal = {
    weapon_1 : SWeapon;
    weapon_2 : SWeapon;
    aid: AccountIdentifier;
    startStaketime: Time;
    lastClaimTime: Time;
    eCoal_amount: Nat;
    rank : RankValue;
  };

  type StakeOre = {
    character : SCharacter;
    weapon : SWeapon;
    aid: AccountIdentifier;
    startStaketime: Time;
    lastClaimTime: Time;
    eOre_amount: Nat;
    rank : RankValue;
  };

  type StakeAdit = {
    character : SCharacter;
    weapon : SWeapon;
    aid: AccountIdentifier;
    startStaketime: Time;
    lastClaimTime: Time;
    eAdit_amount: Nat;
  };

  type Collections = {
    #dwarves : TokenIdentifier__1;
    #weapons : TokenIdentifier__1;
  };

  type TokenInfo = {
    #dwarves : ?CharactersMetadata;
    #weapons : ?Weapons;
  };

  type TokenInfoRarity = {
    tokenInfo : TokenInfo;
    tokenRarity : ?Text;
  };

    type TokenRarity = {
    tokenRarity : Text;
  };

  private stable var _charactersState : [(TokenIdentifier, CharactersMetadata)] = [];
  private var _characters : HashMap.HashMap<TokenIdentifier, CharactersMetadata> = HashMap.fromIter(_charactersState.vals(), 0, Text.equal, Text.hash);
  private stable var _weaponsState : [(TokenIdentifier, Weapons)] = [];
  private var _weapons : HashMap.HashMap<TokenIdentifier, Weapons> = HashMap.fromIter(_weaponsState.vals(), 0, Text.equal, Text.hash);
  private stable var _stakeState : [(TokenIdentifier, Stake)] = [];
  private var _stake : HashMap.HashMap<TokenIdentifier, Stake> = HashMap.fromIter(_stakeState.vals(), 0, Text.equal, Text.hash); //пополнение массива
  private stable var _stakeCoalState : [(TokenIdentifier, StakeCoal)] = [];
  private var _stakeCoal : HashMap.HashMap<TokenIdentifier, StakeCoal> = HashMap.fromIter(_stakeCoalState.vals(), 0, Text.equal, Text.hash); //Стейкинг угля
  private stable var _tokensRarityState : [(TokenIdentifier, TokenRarity)] = [];
  private var _tokensRarity : HashMap.HashMap<TokenIdentifier, TokenRarity> = HashMap.fromIter(_tokensRarityState.vals(), 0, Text.equal, Text.hash);
  private stable var _stakeOreState : [(TokenIdentifier, StakeOre)] = [];
  private var _stakeOre : HashMap.HashMap<TokenIdentifier, StakeOre> = HashMap.fromIter(_stakeOreState.vals(), 0, Text.equal, Text.hash); //Стейкинг руды
  private stable var _stakeAditState : [(TokenIdentifier, StakeAdit)] = [];
  private var _stakeAdit : HashMap.HashMap<TokenIdentifier, StakeAdit> = HashMap.fromIter(_stakeAditState.vals(), 0, Text.equal, Text.hash); //Стейкинг камня

  public shared(msg) func transfer_tokens(tokenName : Text, to : AccountIdentifier, amount: Nat) : async Result.Result<Text, Text>{ // универсальный трансфер валюты
    var owner : AccountIdentifier = "";
    if (AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == AID.fromPrincipal(Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"), ?AID.SUBACCOUNT_ZERO)) {
      owner := AID.fromPrincipal(Principal.fromActor(this), ?AID.SUBACCOUNT_ZERO);
    } 
    else{  owner := AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO);};
    if (tokenName == "gold"){
      let args : eGold.TransferRequest = 
      {
        to = #address(to);
        token = "";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_eGold(args);
      return #ok("successful eGold transfer!");
    }
    else if (tokenName == "ore"){
      let args : eOre.TransferRequest = 
      {
        to = #address(to);
        token = "";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_eOre(args);
    return #ok("successful eOre transfer!");
    }
    else if (tokenName == "coal"){
      let args : eCoal.TransferRequest = 
      {
        to = #address(to);
        token = "";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_eCoal(args);
    return #ok("successful eCoal transfer!");
    }
    else if (tokenName == "adit"){
   let args : eAdit.TransferRequest = 
      {
        to = #address(to);
        token = "";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_eAdit(args);
    return #ok("successful eAdit transfer!");
    }
    else if (tokenName == "lgs"){
   let args : lgs.TransferRequest = 
      {
        to = #address(to);
        token = "";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_lgs(args);
    return #ok("successful lgs transfer!");
    }
     else if (tokenName == "leather"){
   let args : leather.TransferRequest = 
      {
        to = #address(to);
        token = "leather";
        notify = false;
        from = #address(owner);
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = amount;
    };
      let b = await transfer_leather(args);
    return #ok("successful leather transfer!");
    }
     else if (tokenName == "bronze"){
   let args : eBronze.Eimolad_ICRC1_Transfer = 
      {
        to = #address(to);
        fee = null;
        from = #address(owner);
        memo = null;
        created_at_time = null;
        amount = amount;
    };
      let b = await transfer_eBronze(args);
    return #ok("successful eBronze transfer!");
    }
    else {return #err("Error")}
};

  public func getTokenOwner(nftc: Collections) : async AccountIdentifier { // made it public
    switch nftc {
      case (#dwarves tid) {
        let aid : Dwarves.Result_8 = await Dwarves.Dwarves.details(tid);
        switch(aid) {
          case (#ok id) return id.0;
          case (#err err) return "0000";
        };
      };
      case (#weapons tid) {
        let aid : Weapons.Result_6 = await Weapons.Weapons.details(tid);
        switch(aid) {
          case (#ok id) return id.0;
          case (#err err) return "0000";
        };
      };
    };
  };

  public shared(msg) func verification () : async () {
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    for ((token, en) in _stake.entries()){
      switch (_characters.get(en.character.tid)){
        case(?ch){
          if (ch.state != "stake"){
                _stake.delete(token);
            };
        };
        case(_){};
      };
      switch (_weapons.get(en.weapon.tid)){
        case(?wp){
          if (wp.state != "stake"){
              _stake.delete(token);
            };
        };
        case(_){};
      };
    };

    for ((token, ch) in _characters.entries()){
      if (ch.state == "stake"){
        var flag : Bool = false;
        for ((stoken, st) in _stake.entries()){
          if (st.character.tid == token) {flag := true;};
      };
      if (flag == false){
        _characters.put(token, {
          rase = ch.rase;
          modelCanister = ch.modelCanister;
          ledgerCanister = ch.ledgerCanister;
          position = ch.position;
          state = "none"; 
          weapon = ch.weapon; 
          equipment = ch.equipment;
          rarityRate = ch.rarityRate;
          });
        };
      };
    };
    for ((token, wp) in _weapons.entries()){
      if (wp.state == "stake"){
        var flag: Bool = false;
        for ((stoken, st) in _stake.entries()){
          if (st.weapon.tid == token) {flag := true;};
      };
      if (flag == false){
        _weapons.put(token, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "none";
        });
      };
    };
  };
};


public shared(msg) func setStatus() : async (){ // fix of states 
  assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
  for ((token, en) in _stakeOre.entries()){
    switch (_characters.get(en.character.tid)){
      case(?ch){
        if (ch.state == "none"){
          _characters.put(en.character.tid,{
          rase = ch.rase;
          modelCanister = ch.modelCanister;
          ledgerCanister = ch.ledgerCanister;
          position = ch.position;
          state = "stake"; 
          weapon = ch.weapon; 
          equipment = ch.equipment;
          rarityRate = ch.rarityRate;
          });
      };
      };
      case(_){};
    };
    switch (_weapons.get(en.weapon.tid)){
      case(?wp){
        if (wp.state == "none"){
          _weapons.put(en.weapon.tid, {
            weaponType =  wp.weaponType;
            modelCanister = wp.modelCanister;
            ledgerCanister = wp.ledgerCanister;
            state = "stake";
          });
        };
      };
      case(_){};
    };
  };

  for ((token, en) in _stakeAdit.entries()){
    switch (_characters.get(en.character.tid)){
      case(?ch){
        if (ch.state == "none"){
          _characters.put(en.character.tid,{
          rase = ch.rase;
          modelCanister = ch.modelCanister;
          ledgerCanister = ch.ledgerCanister;
          position = ch.position;
          state = "stake"; 
          weapon = ch.weapon; 
          equipment = ch.equipment;
          rarityRate = ch.rarityRate;
          });
      };
      };
      case(_){};
    };
    switch (_weapons.get(en.weapon.tid)){
      case(?wp){
        if (wp.state == "none"){
          _weapons.put(en.weapon.tid, {
            weaponType =  wp.weaponType;
            modelCanister = wp.modelCanister;
            ledgerCanister = wp.ledgerCanister;
            state = "stake";
          });
        };
      };
      case(_){};
      };
    };
  for ((token, en) in _stakeCoal.entries()){
    switch (_weapons.get(en.weapon_1.tid)){
      case(?wp){
        if (wp.state == "none"){
          _weapons.put(en.weapon_1.tid, {
            weaponType =  wp.weaponType;
            modelCanister = wp.modelCanister;
            ledgerCanister = wp.ledgerCanister;
            state = "stake";
          });
        };
      };
      case(_){};
    };
    switch (_weapons.get(en.weapon_2.tid)){
      case(?wp){
        if (wp.state == "none"){
          _weapons.put(en.weapon_2.tid, {
            weaponType =  wp.weaponType;
            modelCanister = wp.modelCanister;
            ledgerCanister = wp.ledgerCanister;
            state = "stake";
          });
        };
      };
      case(_){};
    };
  };
};
  public shared(msg) func updateCharacter(tid: TokenIdentifier, chmd: CharactersMetadata) : async () {
    let owner = await getTokenOwner(#weapons(tid));
    assert((AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner) or (msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe")));
    _characters.put(tid, chmd);
  };

  public shared(msg) func updateWeapon(tid: TokenIdentifier, wp: Weapons) : async () {
    let owner = await getTokenOwner(#weapons(tid));
    assert((AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner) or (msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe")));
    _weapons.put(tid, wp);
  };

  public shared(msg) func updateTokenRarity(tid: TokenIdentifier, wpr: TokenRarity) : async () {
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    _tokensRarity.put(tid, wpr);
  };

  public func getCharacters() : async [(TokenIdentifier, CharactersMetadata)] {
    Iter.toArray(_characters.entries());
  };

  public func getWeapons() : async [(TokenIdentifier, Weapons)] {
    Iter.toArray(_weapons.entries());
  };

  public func getTokensRarity() : async [(TokenIdentifier, TokenRarity)]{
    Iter.toArray(_tokensRarity.entries());
  };

  public query func getTokenInfo(tid: Collections) : async TokenInfo {
    switch tid {
      case (#dwarves id) {
        return #dwarves(_characters.get(id));
      };
      case (#weapons id) {
        return #weapons(_weapons.get(id));
      };
    };
  };

  public query func getTokenInfoRare(tid: Collections) : async TokenInfoRarity { // ПЕРЕПРОВЕРИТЬ! 
    var rare : Text = "";
    switch tid {
      case (#dwarves id) {
        switch (_tokensRarity.get(id)){
         case (?tr) {rare := tr.tokenRarity;};
         case(_){};
        };
        var dw : TokenInfoRarity = {tokenInfo = #dwarves(_characters.get(id)); tokenRarity = ?rare;};
        return dw;
      };
      case (#weapons id) {
        switch (_tokensRarity.get(id)){
         case (?tr) {rare := tr.tokenRarity;};
         case(_){};
        };
        var wp : TokenInfoRarity = {tokenInfo = #weapons(_weapons.get(id)); tokenRarity = ?rare;};
        return wp;
      };
    };
  };

  private func rateFromDays(days : Int) : async RankValue{ // Получение кэфа в зависимости от кол-ва дней
    var r : RankValue = 0;
    if (days < 30) {r:= 10};
    if (days >= 30 and days < 60 ) {r:= 11};
    if (days >= 60 and days < 90 ) {r:= 12};  
    if (days >= 90 and days < 120 ) {r:= 13};
    if (days >= 120 and days < 150 ) {r:= 14};
    if (days >= 150 and days < 180 ) {r:= 15};
    if (days >= 180 and days < 210 ) {r:= 17};
    if (days >= 210) {r:= 20};
    return r;
  };

  private func rateFromRarity(rarityRate : RarityRate) : async RankValue{ // Получение кэфа в зависимости от NRI
    var r : RankValue = 0;
    if (rarityRate < 20) {r:= 10};
    if (rarityRate >= 20 and rarityRate < 30 ) {r:= 11};
    if (rarityRate >= 30 and rarityRate < 40 ) {r:= 12};
    if (rarityRate >= 40 and rarityRate < 50 ) {r:= 13};
    if (rarityRate >= 50 and rarityRate < 90 ) {r:= 14};
    if (rarityRate >= 90 and rarityRate < 99 ) {r:= 15};
    if (rarityRate >= 99 and rarityRate < 100 ) {r:= 20};
    if (rarityRate == 100) {r:= 30};
    return r;
  };


  private func transfer_dwarves(tr : Dwarves.TransferRequest) : async Dwarves.TransferResponse {
    return await Dwarves.Dwarves.transfer(tr); 
  };

  private func transfer_weapons(tr : Weapons.TransferRequest) : async Weapons.TransferResponse {
    return await Weapons.Weapons.transfer(tr); 
  };
  //==============================================================================

  //===================================COALSTAKING================================
  public func getStakedCoal() : async [(TokenIdentifier, StakeCoal)] {
    Iter.toArray(_stakeCoal.entries());
  };

  public shared(msg) func setStakeCoal(st : StakeCoal) : async () {
    let owner = await getTokenOwner(#weapons(st.weapon_1.tid));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner);
    assert (st.weapon_1.tid != st.weapon_2.tid); // проверить работает ли ассерт
    switch (_weapons.get(st.weapon_1.tid)) {
      case (?wp) {
        _weapons.put(st.weapon_1.tid, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "stake";
        });
     };
      case (_) {
        return ();
      };
    };
    switch (_weapons.get(st.weapon_2.tid)) {
      case (?wp) {
        _weapons.put(st.weapon_2.tid, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "stake";
        });
      };
      case (_) {
        return ();
      };
    };
    _stakeCoal.put(st.weapon_1.tid, st);
  };

  public shared(msg) func unStakeCoal(token : TokenIdentifier) : async () { //Новый анстейк
    let owner = await getTokenOwner(#weapons(token));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner); 
    switch (_stakeCoal.get(token)){
      case (?st){
        switch(_weapons.get(st.weapon_1.tid)){
          case (?wp) {
            _weapons.put(st.weapon_1.tid, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){};
        };
        switch(_weapons.get(st.weapon_2.tid)){
          case (?wp) {
            _weapons.put(st.weapon_2.tid, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){};
        };
      };
      case(_){};
    };
    _stakeCoal.delete(token);
  };

  public shared(msg) func getStakeCoalFromAID (): async [StakeCoal] { //функция получения записей стекинга по АИД
    var res : [StakeCoal] = [];
    for ((tid, en) in _stakeCoal.entries()){
      if (en.aid == AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO)){
        res := Array.append(res, [en]);
      };
    };
    return res;
  };

  private func checkWeek() : async(){
    for ((tid, en) in _stakeCoal.entries()){
      var claimTime : Time = 24 * 60 * 60 * 1000 * 1000 * 1000;//86400000000000;
      if (Int.div((Time.now() - en.lastClaimTime), claimTime) >= 1) {
        var count = Int.div((Time.now() - en.startStaketime), claimTime); // count of staking day
        var rankrate = await rateFromDays(count); // Пока что такие же кэфы как и в дефолтном стейкинге
        var amount = rankrate;
        _stakeCoal.put(tid, 
        {
          weapon_1 = en.weapon_1;
          weapon_2 = en.weapon_2;
          aid = en.aid;
          startStaketime = en.startStaketime;
          lastClaimTime = Time.now();
          eCoal_amount = amount;
          rank = rankrate;
        }); 
        if (Int.rem(count, 7) == 0){
          let b = await claimCoalTokens(en.aid, amount);
       };
      };
    };
      return ();  
  };

  private func claimCoalTokens(to : AccountIdentifier, amount : eCoal.Balance) : async Result.Result<Text, ()> {
    let args : eCoal.TransferRequest = {
      to = #address(to);
      token = "";
      notify = false;
      from = #principal(Principal.fromActor(this));
      memo = [];
      subaccount = ?AID.SUBACCOUNT_ZERO;
      amount = amount;
    };
    let b = await transfer_eCoal(args);
    return #ok("successfully delivered tokens");
  };
  //==============================================================================

  //===================================ORESTAKING================================
  public func getStakedOre() : async [(TokenIdentifier, StakeOre)] {
    Iter.toArray(_stakeOre.entries());
  };

  public shared(msg) func setStakeOre(st : StakeOre) : async () {
    let owner = await getTokenOwner(#dwarves(st.character.tid));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner);
    var weapon_rarity : Text = "";
    switch (_tokensRarity.get(st.weapon.tid)){
      case (?tr) {  
        weapon_rarity := tr.tokenRarity;
      };
      case (_){};
    };
    assert(weapon_rarity == "rare"); // ассерт на проверку редкости
    switch (_weapons.get(st.weapon.tid)) {
      case (?wp) {
        _weapons.put(st.weapon.tid, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "stake";
        });
      };
      case (_) {
        return ();
      };
    };
    switch (_characters.get(st.character.tid)) {
      case (?ch) {
        _characters.put(st.character.tid, {
        rase = ch.rase;
        modelCanister = ch.modelCanister;
        ledgerCanister = ch.ledgerCanister;
        position = ch.position;
        state = "stake"; 
        weapon = ch.weapon; 
        equipment = ch.equipment;
        rarityRate = ch.rarityRate;
        });
      };
      case (_) {
        return ();
      }; 
  };
    _stakeOre.put(st.character.tid, st);
  };


  public shared(msg) func unStakeOre(token : TokenIdentifier) : async () { 
    let owner = await getTokenOwner(#dwarves(token));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner); 
    switch (_stakeOre.get(token)){
      case (?st){
        switch(_weapons.get(st.weapon.tid)){
          case (?wp) {
            _weapons.put(st.weapon.tid, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){};
        };
        switch (_characters.get(st.character.tid)){
          case (?ch) {
            _characters.put(token, {
            rase = ch.rase;
            modelCanister = ch.modelCanister;
            ledgerCanister = ch.ledgerCanister;
            position = ch.position;
            state = "wrapped"; 
            weapon = ch.weapon; 
            equipment = ch.equipment;
            rarityRate = ch.rarityRate;
            });
          };
          case (_) {}; 
      };
      };
      case(_){};
    };
    _stakeOre.delete(token);
  };

  public shared(msg) func getStakeOreFromAID (): async [StakeOre] { //функция получения записей стекинга по АИД
    var res : [StakeOre] = [];
    for ((tid, en) in _stakeOre.entries()){
      if (en.aid == AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO)){
        res := Array.append(res, [en]);
      };
    };
    return res;
  };
  private func checkMonthOre() : async(){
    for ((tid, en) in _stakeOre.entries()){
      var claimTime : Time = 24 * 60 * 60 * 1000 * 1000 * 1000;//86400000000000;
      if (Int.div((Time.now() - en.lastClaimTime), claimTime) >= 1) { // now we check it everyday, not every 30 days
      var count = Int.div((Time.now() - en.startStaketime), claimTime); // count of staking day
        var rankrate = await rateFromDays(count);
        var amount = rankrate;
          _stakeOre.put(tid, 
        {
          character = en.character;
          weapon = en.weapon;
          aid = en.aid;
          startStaketime = en.startStaketime;
          lastClaimTime = Time.now();
          eOre_amount = amount;
          rank = rankrate;
        }); 
        if (Int.rem(count, 30) == 0){ // если количество дней делится на 30 без остатка, то начисляем бабки
          let b = await claimOreTokens(en.aid, amount);
        };
      };
    };
      return ();   
  };

  private func claimOreTokens(to : AccountIdentifier, amount : eOre.Balance) : async Result.Result<Text, ()> {
    let args : eOre.TransferRequest = {
      to = #address(to);
      token = "";
      notify = false;
      from = #principal(Principal.fromActor(this));
      memo = [];
      subaccount = ?AID.SUBACCOUNT_ZERO;
      amount = amount;
    };
    let b = await transfer_eOre(args);
    return #ok("successfully delivered tokens");
    };
  //==============================================================================

  //===================================ADITSTAKING================================
  public func getStakedAdit() : async [(TokenIdentifier, StakeAdit)] {
    Iter.toArray(_stakeAdit.entries());
  };

  public shared(msg) func setStakeAdit(st : StakeAdit) : async () {
    let owner = await getTokenOwner(#dwarves(st.character.tid));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner);
    var weapon_rarity : Text = "";
    switch (_tokensRarity.get(st.weapon.tid)){
      case (?tr) {  
        weapon_rarity := tr.tokenRarity;
      };
      case (_){};
    };
    assert(weapon_rarity == "superrare"); // ассерт на проверку редкости
    switch (_weapons.get(st.weapon.tid)) {
      case (?wp) {
        _weapons.put(st.weapon.tid, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "stake";
        });
      };
      case (_) {
        return ();
      };
    };
    switch (_characters.get(st.character.tid)) {
      case (?ch) {
        _characters.put(st.character.tid, {
        rase = ch.rase;
        modelCanister = ch.modelCanister;
        ledgerCanister = ch.ledgerCanister;
        position = ch.position;
        state = "stake"; 
        weapon = ch.weapon; 
        equipment = ch.equipment;
        rarityRate = ch.rarityRate;
        });
      };
      case (_) {
        return ();
      }; 
  };
    _stakeAdit.put(st.character.tid, st);
  };


  public shared(msg) func unStakeAdit(token : TokenIdentifier) : async () { 
    let owner = await getTokenOwner(#dwarves(token));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner); 
    switch (_stakeAdit.get(token)){
      case (?st){
        switch(_weapons.get(st.weapon.tid)){
          case (?wp) {
            _weapons.put(st.weapon.tid, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){};
        };
        switch (_characters.get(st.character.tid)){
          case (?ch) {
            _characters.put(token, {
            rase = ch.rase;
            modelCanister = ch.modelCanister;
            ledgerCanister = ch.ledgerCanister;
            position = ch.position;
            state = "wrapped"; 
            weapon = ch.weapon; 
            equipment = ch.equipment;
            rarityRate = ch.rarityRate;
            });
          };
          case (_) {}; 
      };
      };
      case(_){};
    };
    _stakeAdit.delete(token);
  };

  public shared(msg) func getStakeAditFromAID (): async [StakeAdit] { //функция получения записей стекинга по АИД
    var res : [StakeAdit] = [];
    for ((tid, en) in _stakeAdit.entries()){
      if (en.aid == AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO)){
        res := Array.append(res, [en]);
      };
    };
    return res;
  };

  private func checkMonthAdit() : async(){
    for ((tid, en) in _stakeAdit.entries()){
      var claimTime : Time = 24 * 60 * 60 * 1000 * 1000 * 1000;//86400000000000;
        if (Int.div((Time.now() - en.lastClaimTime), claimTime) >= 1) { // now we check it everyday, not every 30 days
          var count = Int.div((Time.now() - en.startStaketime), claimTime); // count of staking day
          var amount = 1;
            _stakeAdit.put(tid, 
          {
            character = en.character;
            weapon = en.weapon;
            aid = en.aid;
            startStaketime = en.startStaketime;
            lastClaimTime = Time.now();
            eAdit_amount = amount;
          }); 
          if (Int.rem(count, 30) == 0){ // если количество дней делится на 30 без остатка, то начисляем бабки
            let b = await claimAditTokens(en.aid, amount);
          };
        };
      };
    return ();   
  };

  private func claimAditTokens(to : AccountIdentifier, amount : eAdit.Balance) : async Result.Result<Text, ()> {
    let args : eAdit.TransferRequest = {
      to = #address(to);
      token = "";
      notify = false;
      from = #principal(Principal.fromActor(this));
      memo = [];
      subaccount = ?AID.SUBACCOUNT_ZERO;
      amount = amount;
    };
    let b = await transfer_eAdit(args);
    return #ok("successfully delivered tokens");
  };
  //==============================================================================


  //=======================================STAKING================================
  public func getStaked() : async [(TokenIdentifier, Stake)] {
    Iter.toArray(_stake.entries());
  };

  public shared(msg) func setStake(st : Stake) : async () {
    let owner = await getTokenOwner(#dwarves(st.character.tid));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner);
    var nri : RarityRate = 0; // hz mojno li tak
    switch (_weapons.get(st.weapon.tid)) {
      case (?wp) {
        _weapons.put(st.weapon.tid, {
          weaponType =  wp.weaponType;
          modelCanister = wp.modelCanister;
          ledgerCanister = wp.ledgerCanister;
          state = "stake";
        });
      };
      case (_) {
        return ();
      };
    };
    switch (_characters.get(st.character.tid)) {
      case (?ch) {
        nri := ch.rarityRate;
        _characters.put(st.character.tid, {
        rase = ch.rase;
        modelCanister = ch.modelCanister;
        ledgerCanister = ch.ledgerCanister;
        position = ch.position;
        state = "stake"; 
        weapon = ch.weapon; 
        equipment = ch.equipment;
        rarityRate = ch.rarityRate;
        });
      };
      case (_) {
        return ();
    }; 
  };
    var rarity = await rateFromRarity(nri);
    _stake.put(st.character.tid, {
      character = st.character;
      weapon = st.weapon;
      aid = st.aid;
      startStaketime = st.startStaketime;
      lastClaimTime = st.lastClaimTime;
      eGold_amount = st.rank*rarity;
      rarityRate = rarity;  
      rank = st.rank;
    });
  };

  public shared(msg) func unStake(token : TokenIdentifier) : async () { //Новый анстейк
    let owner = await getTokenOwner(#dwarves(token));
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner); 
    switch (_stake.get(token)){
      case (?st){
        switch(_weapons.get(st.weapon.tid)){
          case (?wp) {
            _weapons.put(st.weapon.tid, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){};
        };
        switch (_characters.get(st.character.tid)){
          case (?ch) {
            _characters.put(token, {
            rase = ch.rase;
            modelCanister = ch.modelCanister;
            ledgerCanister = ch.ledgerCanister;
            position = ch.position;
            state = "wrapped"; 
            weapon = ch.weapon; 
            equipment = ch.equipment;
            rarityRate = ch.rarityRate;
            });
          };
          case (_) {}; 
        };
      };
      case(_){};
    };
    _stake.delete(token);
  };
  public shared(msg) func wrap (tokens : [TokenIdentifier]) : async Result.Result<Text, ()> { //пакетный wrap
    for (tokenId in tokens.vals()){
      let owner_dw = await getTokenOwner(#dwarves(tokenId));
      let owner_wp = await getTokenOwner(#weapons(tokenId));
      if (owner_dw != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_dw);
        switch (_characters.get(tokenId)){
          case (?ch) {
            _characters.put(tokenId, {
            rase = ch.rase;
            modelCanister = ch.modelCanister;
            ledgerCanister = ch.ledgerCanister;
            position = ch.position;
            state = "wrapped"; 
            weapon = ch.weapon; 
            equipment = ch.equipment;
            rarityRate = ch.rarityRate;
            });
          };
          case(_){
            return #err();
          };
        };
      }
      else if (owner_wp != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_wp);
        switch (_weapons.get(tokenId)){
          case (?wp) {
            _weapons.put(tokenId, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "wrapped";
            });
          };
          case(_){
            return #err();
          };
        };
      };
    };
  return #ok("successful wrap");
  };


  public shared(msg) func unWrap(tokens : [TokenIdentifier]) : async Result.Result<Text, ()> { // пакетно меняет стейт на none
    for (tokenId in tokens.vals()){
      let owner_dw = await getTokenOwner(#dwarves(tokenId));
      let owner_wp = await getTokenOwner(#weapons(tokenId));
      if (owner_dw != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_dw);
        switch (_characters.get(tokenId)){
          case (?ch) {
            if (ch.state != "stake"){
              _characters.put(tokenId, {
              rase = ch.rase;
              modelCanister = ch.modelCanister;
              ledgerCanister = ch.ledgerCanister;
              position = ch.position;
              state = "none"; 
              weapon = ch.weapon; 
              equipment = ch.equipment;
              rarityRate = ch.rarityRate;
              });
          };
          };
          case(_){
            return #err();
          };
        };
      }
      else if (owner_wp != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_wp);
        switch (_weapons.get(tokenId)){
          case (?wp) {
            if (wp.state != "stake"){
              _weapons.put(tokenId, {
                weaponType =  wp.weaponType;
                modelCanister = wp.modelCanister;
                ledgerCanister = wp.ledgerCanister;
                state = "none";
              });
            };
          };
          case(_){
            return #err();
          };
        };
      };
    };
    return #ok("successful unwrap");
  };

  public shared(msg) func getStakeFromAID (): async [Stake] { //функция получения записей стекинга по АИД
    var res : [Stake] = [];
    for ((tid, en) in _stake.entries()){
      if (en.aid == AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO)){
        res := Array.append(res, [en]);
      };
    };
    return res;
  };

  public func textToNat( txt : Text) : async Nat {
    assert(txt.size() > 0);
    let chars = txt.chars();
    var num : Nat = 0;
    for (v in chars){
        let charToNum = Nat32.toNat(Char.toNat32(v)-48);
        assert(charToNum >= 0 and charToNum <= 9);
        num := num * 10 +  charToNum;          
    };
    num;
    };

  private func checkDay() : async(){
    for ((tid, en) in _stake.entries()){
       var t : Time = Time.now();
       var claimTime : Time = 24 * 60 * 60 * 1000 * 1000 * 1000;//86400000000000;
       var daysOfLastClaim = await textToNat(Int.toText(Int.div((Time.now() - en.lastClaimTime), claimTime)));

      if (daysOfLastClaim >= 1) {
        var count = Int.div((Time.now() - en.startStaketime), claimTime); // count of staking day
        var rankrate = await rateFromDays(count);
        var amount = daysOfLastClaim * rankrate * en.rarityRate;
        let b = await claimTokens(en.aid, amount);
          _stake.put(tid,
        {
          character = en.character;
          weapon = en.weapon;
          aid = en.aid;
          startStaketime = en.startStaketime;
          lastClaimTime = Time.now();
          eGold_amount = amount;
          rarityRate = en.rarityRate;
          rank = rankrate;
        }); 
      };
    };
    return ();  
  };
  
  private func claimTokens(to : AccountIdentifier, amount : eGold.Balance) : async Result.Result<Text, ()> {
    let args : eGold.TransferRequest = {
      to = #address(to);
      token = "";
      notify = false;
      from = #principal(Principal.fromActor(this));
      memo = [];
      subaccount = ?AID.SUBACCOUNT_ZERO;
      amount = amount;
    };
    let b = await transfer_eGold(args);
    return #ok("successfully delivered tokens");
  };

  public shared(msg) func transferMany(to : AccountIdentifier, tokens : [TokenIdentifier], subaccount : Dwarves.SubAccount) : async Result.Result<Text, Dwarves.TransferResponse> { // пакетный трансфер
    var _tokens : [TokenIdentifier] = [];
    _tokens := Array.append(_tokens, tokens);
    for (tokenId in _tokens.vals()){
      let owner_dw = await getTokenOwner(#dwarves(tokenId));
      let owner_wp = await getTokenOwner(#weapons(tokenId));
      if (owner_dw != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?subaccount) == owner_dw);
        switch (_characters.get(tokenId)){
          case (?ch) {
          if (ch.state == "none") {
            let args : Dwarves.TransferRequest = {
              to = #address(to);
              token = tokenId;
              notify = false;
              from = #address(owner_dw);
              memo = [];
              subaccount = ?subaccount;
              amount = 1;
              };
            let b = await transfer_dwarves(args);
            switch (b) {
              case (#ok balance){if (balance == 0) {_tokens := Array.append(_tokens, [tokenId])}};
              case (#err err){return #err(#err(err))};
            };
            };
          };
          case(_){
            return #err(#err(#Other("no tid")));
          };
        };
      }
      else if (owner_wp != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?subaccount) == owner_wp);
        switch (_weapons.get(tokenId)){
          case (?wp) {
            if (wp.state == "none") {
              let args : Weapons.TransferRequest = {
                to = #address(to);
                token = tokenId;
                notify = false;
                from = #address(owner_wp);
                memo = [];
                subaccount = ?subaccount;
                amount = 1;
              };
              let b = await transfer_weapons(args);
              switch (b) {
                case (#ok balance){if (balance == 0) {_tokens := Array.append(_tokens, [tokenId])}};
                case (#err err){return #err(#err(err))};
              };
            };
          };
          case(_){
            return #err(#err(#Other("no tid")));
          };
        };
      };
    };
  return #ok("successful package transfer");
  };
  //==============================================================================

  //===================================MARKET====================================
  public shared(msg) func sell (tokens : [TokenIdentifier]) : async Result.Result<Text, ()> { //пакетный listing
    for (tokenId in tokens.vals()){
      let owner_dw = await getTokenOwner(#dwarves(tokenId));
      let owner_wp = await getTokenOwner(#weapons(tokenId));
      if (owner_dw != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_dw);
        switch (_characters.get(tokenId)){
          case (?ch) {
            _characters.put(tokenId, {
            rase = ch.rase;
            modelCanister = ch.modelCanister;
            ledgerCanister = ch.ledgerCanister;
            position = ch.position;
            state = "listed"; 
            weapon = ch.weapon; 
            equipment = ch.equipment;
            rarityRate = ch.rarityRate;
            });
          };
          case(_){
            return #err();
          };
        };
      }
      else if (owner_wp != "0000"){
        assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == owner_wp);
        switch (_weapons.get(tokenId)){
          case (?wp) {
            _weapons.put(tokenId, {
              weaponType =  wp.weaponType;
              modelCanister = wp.modelCanister;
              ledgerCanister = wp.ledgerCanister;
              state = "listed";
            });
          };
          case(_){
            return #err();
          };
        };
      };
    };
  return #ok("successful listing");
  };

  //==============================================================================

  //=============================GAME FUNCS=======================================
  type CommonError = {
      #InvalidToken : TokenIdentifier;
      #Other : Text;
    };

  type UserAccount = {
    aid : AccountIdentifier;
    charId : TokenIdentifier;
    equipment : CurrentEquipment;
    // vector : [Float];
    name: Text;
    experience : Nat;
    quest: [Text];
  };

  type UpdatedUserAccount = {
    charId : TokenIdentifier;
    equipment : CurrentEquipment;
    position : [Float];
    name: Text;
    quest: [Text];
  };

  private stable var _userAccountState : [(TokenIdentifier, UpdatedUserAccount)] = []; 
  private var _userAccount : HashMap.HashMap<TokenIdentifier, UpdatedUserAccount> = HashMap.fromIter(_userAccountState.vals(), 0, Text.equal, Text.hash);

  private stable var _attributesState : [(TokenIdentifier, Text)] = [];
  private var _attributes : HashMap.HashMap<TokenIdentifier, Text> = HashMap.fromIter(_attributesState.vals(), 0, Text.equal, Text.hash);

  type UserName = {
    tid : TokenIdentifier;
    name : Text;
  };

  public shared(msg) func updateHashMap () : async (){ // обновление хэшмапы игры
  // assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    for ((tid, userData) in _newUserAccount.entries()){
      _userAccount.put(tid, {
        charId = tid;
        equipment = userData.equipment;
        position = [0,0,0];
        name = userData.name;
        quest = userData.quest;
      });
    };
  };

  public shared(msg) func fillAttributes () : async (){ // заполнение дефолтных атрибутов
    // assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    for (tid in _newUserAccount.keys()){
      _attributes.put(tid, getDefaultAttributes("dwarves"));
    };
  };

  public func getAttributes() : async [(TokenIdentifier, Text)] {
      Iter.toArray(_attributes.entries());
    };

  private func getDefaultAttributes (race : Text) : Text {
    var t : Text = "";
    if (race == "dwarves") {
      t := "{\"experience\": 0,\"level\": 1,\"strength\": 50,\"attack\" : 50,\"st_resist\" : 5,\"hp_regen\" : 2.5,\"dexterity\" : 30,\"attack_speed\" : 30, \"evasion\" : 3,\"accuracy\" : 3,\"intelligence\" : 40,\"m_attack\" : 40,\"mp_regen\" : 2,\"move_speed\" : 80,\"initial_attack_speed\" : 600,\"initial_evasion\" : 0,\"initial_ accuracy\" : 70,\"critical_chance\" : 0,\"spell_speed\" : 0,\"cooldown\" : 0,\"defence\" : 0, \"m_resist\" : 0,\"set_bonus\" : 0}";
    };
    return t;
  };

  private stable var _newUserAccountState : [(TokenIdentifier, UserAccount)] = [];
  private var _newUserAccount : HashMap.HashMap<TokenIdentifier, UserAccount> = HashMap.fromIter(_newUserAccountState.vals(), 0, Text.equal, Text.hash);

  public func getNewAccount() : async [(TokenIdentifier, UserAccount)] {
      Iter.toArray(_newUserAccount.entries());
  };

  public func getAccounts() : async [(TokenIdentifier, UpdatedUserAccount)] {
      Iter.toArray(_userAccount.entries());
  };

  public func getUnsigned(tid : TokenIdentifier) : async ?TokenIdentifier{
    switch (_userAccount.get(tid)){
      case (?ud) {return null};
      case (_) {return ?tid};
    };
  };

  public func getSigned(tid : TokenIdentifier) : async ?UserName{
      switch (_userAccount.get(tid)){
        case (?ud) {return ?{tid = tid; name = ud.name}};
        case (_) {return null};
      };
    };

  public shared(msg) func changeName(tid : TokenIdentifier, name : Text, subaccount : [Nat8]) : async Result.Result<Text, CommonError>{
    let owner = await getTokenOwner(#dwarves(tid));
    assert(AID.fromPrincipal(msg.caller, ?subaccount) == owner);
    switch (_userAccount.get(tid)){
      case(?userData){
        var newUserData : UpdatedUserAccount = {
          charId = userData.charId; 
          equipment = userData.equipment;
          position = userData.position;
          name = name; // update name
          quest = userData.quest;
        };
        _userAccount.put(tid, newUserData);
        return #ok("successful changed name!")};
      case (_){return #err(#Other("This is not registred character in changeName func!"))};
    };
  };

  private func newGetTokenOwner (tid : TokenIdentifier) : async AccountIdentifier {
    let canisterBlob = Core.TokenIdentifier.decode(tid).canister;
    let ledger = Principal.toText(Principal.fromBlob(Blob.fromArray(canisterBlob)));
    let canister : Nft.nftActor = actor (ledger);
    let aid : Nft.Result_9 = await canister.details(tid);
        switch(aid) {
          case (#ok id) return id.0;
          case (#err err) return "0000";
        };
  };
  public shared(msg) func registryAcc(tid : TokenIdentifier, name : Text, subaccount : [Nat8]): async Result.Result<Text, CommonError>{ // add #ok and #err
    let owner = await newGetTokenOwner(tid);
    assert(AID.fromPrincipal(msg.caller, ?subaccount) == owner);
    switch (_userAccount.get(tid)){
      case (?ud){return #err(#Other("That character has already registred"))};
      case (_){
        _userAccount.put(tid, {
              charId = tid; 
              equipment = switch (_characters.get(tid)){
              case(?ch){ch.equipment};
              case(_){[0,0,0,0,0]};};
              position = [0,0,0];
              name = name; 
              quest = [];
        });
        _attributes.put(tid, getDefaultAttributes(switch (_characters.get(tid)){
              case(?ch){ch.rase};
              case(_){""};}));
      return #ok("successful registry!")
      };
    };
  };

  public func deleteAcc (tid : TokenIdentifier) : async (){ // DELETE BEFORE MAIN UPDATE
    _userAccount.delete(tid);
    _attributes.delete(tid);
  };

  public shared(msg) func startGame (tid : TokenIdentifier, subaccount : [Nat8]) : async Result.Result<(UpdatedUserAccount, Text), CommonError>{
    let owner = await newGetTokenOwner(tid);
    assert(AID.fromPrincipal(msg.caller, ?subaccount) == owner);
    switch (_characters.get(tid)){
      case(?ch){
        switch (_userAccount.get(tid)){
        case(?userData){
          switch (_attributes.get(tid)){
            case(?att){
              return #ok(userData, att)
              };
            case (_){return #err(#Other("Some error in getting attributes startGameFunc"))};
          };
        };
        case (_){return #err(#Other("Some error in getting user acc startGameFunc"))};
      };
      };
      case(_){return #err(#Other("Can't find character with that tid"))};
    };
  };

  public shared(msg) func rewardLgs (aid : AccountIdentifier) : async lgs.TransferResponse {
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == aid);  //aid
    let args : lgs.TransferRequest = 
      {
        to = #address(aid);
        token = "";
        notify = false;
        from = #principal(Principal.fromActor(this));
        memo = [];
        subaccount = ?AID.SUBACCOUNT_ZERO;
        amount = 1;
    };
    let b = await transfer_lgs(args);
    switch (b) {
      case (#ok balance){
        return #ok(balance);
        };
      case (#err err){return #err(err)};
    };  
  };

  public shared(msg) func rewardLeather (aid : AccountIdentifier) : async TokenCanister.TransferResponse {
    assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == aid);  //aid
    let canister : TokenCanister.tokenCanisterActor = actor ("4kf7n-uiaaa-aaaan-qapuq-cai");
    let b = await canister.transferFromCanister(1, #address(aid));
    switch (b) {
      case (#ok balance){
        return #ok(balance);
        };
      case (#err err){return #err(err)};
    };  
  };

  public shared(msg) func rewardLoot(canisterId : Text, owner : Text, subaccount : [Nat8], amount : Nat) : async Result.Result<Nat, Text> {
    assert(msg.caller == Principal.fromText(owner)); 
    let canister : icrcDid.icrcActor = actor(canisterId);
    let b = await canister.transferFromCanisterToPrincipal(owner, ?Blob.fromArray(subaccount), amount);
    switch (b) {
      case (#Ok balance){
        return #ok(balance);
        };
      case (#Err err){return #err("Error")};
    };  
  };

  public shared(msg) func useLoot (canisterId : Text, from_owner : Text, from_subaccount : [Nat8], amount : Nat ) : async icrcDid.TransferResult {
    let owner = AID.fromPrincipal(msg.caller, ?from_subaccount); 
    assert(msg.caller == Principal.fromText(from_owner)); 
    let canister : icrcDid.icrcActor = actor(canisterId);
    let args : icrcDid.Eimolad_ICRC1_Transfer = {
      from = #principal({owner = Principal.fromText(from_owner); subaccount = ?from_subaccount});
      to = #address(AID.fromPrincipal(Principal.fromText(canisterId), ?AID.SUBACCOUNT_ZERO));
      amount = amount;
      fee = null;
      memo = null;
      created_at_time = null;
    };
    let tr = await canister.eimolad_icrc1_transfer(args);
  };

  public shared(msg) func saveProgress (userData : UpdatedUserAccount) : async Result.Result<Text, CommonError> {
    // assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == userData.aid);  //aid
    _userAccount.put(userData.charId, userData);
    return #ok("successful saving!");
  };

  public shared(msg) func updateAttributes (tid : TokenIdentifier, att : Text) : async Result.Result<Text, CommonError> {
    // assert(AID.fromPrincipal(msg.caller, ?AID.SUBACCOUNT_ZERO) == userData.aid);  //aid
    _attributes.put(tid, att);
    return #ok("successful saving!");
  };


 
  //==============================================================================

  //======================================BACKUP==================================


  public shared(msg) func saveAllData (): async(){ // будет ли работать с ассертом при вызове из хартбита? 
    assert(msg.caller == Principal.fromText("ylwtf-viaaa-aaaan-qaddq-cai") or (msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe")));
    let s = await backup.backupCanister.backupSave();
  };

  public shared(msg) func useBackup () : async (){
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    let characters : [(TokenIdentifier, CharactersMetadata)] = await backup.backupCanister.getCharacters();
    let weapons : [(TokenIdentifier, Weapons)] = await backup.backupCanister.getWeapons();
    let tokenRarity : [(TokenIdentifier, TokenRarity)] = await backup.backupCanister.getTokensRarity();
    let gold : [(TokenIdentifier, Stake)] = await backup.backupCanister.getStaked();
    let coal : [(TokenIdentifier, StakeCoal)] = await backup.backupCanister.getStakedCoal();
    let ore : [(TokenIdentifier, StakeOre)] = await backup.backupCanister.getStakedOre();
    let adit : [(TokenIdentifier, StakeAdit)] = await backup.backupCanister.getStakedAdit();
    // let userAcc : [(TokenIdentifier, UserAccount)] = await backup.backupCanister.getAccount();

    _characters := HashMap.fromIter(characters.vals(), 0, Text.equal, Text.hash);
    _weapons := HashMap.fromIter(weapons.vals(), 0, Text.equal, Text.hash);
    _tokensRarity := HashMap.fromIter(tokenRarity.vals(), 0, Text.equal, Text.hash);
    _stake := HashMap.fromIter(gold.vals(), 0, Text.equal, Text.hash);
    _stakeCoal := HashMap.fromIter(coal.vals(), 0, Text.equal, Text.hash);
    _stakeOre := HashMap.fromIter(ore.vals(), 0, Text.equal, Text.hash);
    _stakeAdit := HashMap.fromIter(adit.vals(), 0, Text.equal, Text.hash);
    // _userAccount := HashMap.fromIter(userAcc.vals(), 0, Text.equal, Text.hash);
    
  };

  //==============================================================================

  system func preupgrade() {
    _charactersState := Iter.toArray(_characters.entries());
    _weaponsState := Iter.toArray(_weapons.entries());
    _stakeState := Iter.toArray(_stake.entries());
    _stakeCoalState := Iter.toArray(_stakeCoal.entries());
    _tokensRarityState := Iter.toArray(_tokensRarity.entries());
    _stakeOreState := Iter.toArray(_stakeOre.entries());
    _stakeAditState := Iter.toArray(_stakeAdit.entries());
    _userAccountState := Iter.toArray(_userAccount.entries());
    _newUserAccountState := Iter.toArray(_newUserAccount.entries());
    _attributesState := Iter.toArray(_attributes.entries());
  };
  system func postupgrade() {
    _charactersState := [];
    _weaponsState := [];
    _stakeState := []; 
    _stakeCoalState := []; 
    _tokensRarityState := [];
    _stakeOreState := [];
    _stakeAditState := [];
    _userAccountState:= [];
    _newUserAccountState:= [];
    _attributesState := [];
  };

  private var t : Time = Time.now();
  private var checkTime : Time = 60 * 60 * 1000 * 1000 * 1000;//3600 000 000 000;
  private var lastCheck: Time = Time.now();

  private var checkWeekTime : Time = 7 * 24 * 60 * 60 * 1000 * 1000 * 1000;//7 * 86400000000000;
  private var lastCheckWeek: Time = Time.now();


  private stable var _runHeartBeat : Bool = true;

  public shared(msg) func adminKillHeartBeat(): async () {
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    _runHeartBeat := false;
  };
  public shared(msg) func adminStartHeartBeat(): async (){
    assert(msg.caller == Principal.fromText("xocga-4vh64-bidcg-3uxjz-fffxn-exbj4-mgbvl-hlnv6-5syll-ghhkw-eqe"));
    _runHeartBeat := true;
  };
  //с каждым тактом проверять на прохождения часа и затем проходить по массиву state и проверять на прохождение суток
  system func heartbeat() : async () {
    if (_runHeartBeat == true) {
      if (Int.div((Time.now() - lastCheck), checkTime) >= 1) {
        lastCheck := Time.now();
        await checkDay();
        await checkWeek();
        await checkMonthOre();
        await checkMonthAdit();
      };
      if (Int.div((Time.now() - lastCheckWeek), checkWeekTime) >= 1) {
        lastCheckWeek := Time.now();
        await saveAllData();
      }
    };
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
};