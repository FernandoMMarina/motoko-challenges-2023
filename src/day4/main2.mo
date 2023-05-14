import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";

actor class MotoCoin() {
  public type Account = Account.Account;
  var ledger = TrieMap.TrieMap<Account.Account, Nat>(Account.accountsEqual, Account.accountsHash);
    var supply : Nat = 0;

  // Returns the name of the token
   public func name() : async Text{
        return "MotoCoin";
    };


  public func symbol() : async Text{
        return "MOC";
    };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat{
        return supply;
    };

  // Returns the default transfer fee
  public func balanceOf(account : Account): async Nat{ 
        let bal : ?Nat = ledger.get(account);
        switch bal{
            case (null) return 0;
            case (?bal)  return bal;
        };
    };

  // Transfer tokens to another account
 public shared ({caller}) func transfer(from : Account, to : Account, qty : Nat) : async Result.Result<(),Text>{

        if (caller != from.owner) return #err("No puedes enviar activos a nombre de una cuenta que no te pertenece");
        let balFrom = await balanceOf(from);
        if (balFrom < qty) return #err("No hay fondos suficientes para efectuar la operación");
        let balTo = await balanceOf(to);
        ledger.put(from, balFrom - qty);
        ledger.put(from, balTo + qty);
        return #ok ();
    };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
    public shared func airdrop(): async Result.Result<(),Text>{
        //var arrayStudents : [Principal] = await RemoteActor.RemoteActor.getAllStudentsPrincipal();
        //var arrayStudents : [Principal] = await BootcampLocalActor.BootcampLocalActor.getAllStudentsPrincipal();
        let bootcampLocalActor = await BootcampLocalActor.BootcampLocalActor();
        let allStudents = await bootcampLocalActor.getAllStudentsPrincipal();
        var currentBal : Nat = 0;
        for(i in allStudents.vals()){
            var student : Account = {owner = i; subaccount = null};
            currentBal := await balanceOf(student);
            ledger.put(student, currentBal + 100);
            supply += 100;
        };
        return #ok ();
    };
};