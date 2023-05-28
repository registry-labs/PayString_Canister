import Hash "mo:base-0.7.3/Hash";
import Iter "mo:base-0.7.3/Iter";
import Result "mo:base-0.7.3/Result";

import HM "../HashMap";
import Stable "Stable";

module {
    public func fromStable<K, V>(
        s     : HM.HashMap<K, V>,
        hash  : (K) -> Hash.Hash,
        equal : (K, K) -> Bool,
    ) : Result.Result<HashMap<K, V>, V> {
        let m = HashMap<K, V>(hash, equal);
        for ((k, v) in HM.entries(s)) {
            switch (m.replace(k, v)) {
                case (null) {};
                case (? ov) return #err(ov);
            };
        };
        #ok(m);
    };

    public class HashMap<K, V>(
        hash  : (K) -> Hash.Hash,
        equal : (K, K) -> Bool,
    ) : Stable.Stable<HM.HashMap<K, V>> {
        var m : HM.HashMap<K, V> = HM.empty<K, V>();

        private func update((m_, ov) : (HM.HashMap<K, V>, ?V)) : ?V { m := m_; ov; };

        public func size() : Nat = HM.size(m);

        public func delete(k : K) = ignore remove(k);

        public func remove(k : K) : ?V = update(HM.remove<K, V>(m, k, hash, equal));

        public func get(k : K) : ?V = HM.get(m, k, hash, equal);

        public func put(k : K, v : V) = ignore replace(k, v);

        public func replace(k : K, v : V) : ?V = update(HM.insert(m, k, hash, equal, v));

        public func entries() : Iter.Iter<(K, V)> = HM.entries(m);

        public func toStable() : HM.HashMap<K, V> = m;
    };
};
