pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template HashTwo(){ 
    signal input in[2];
    signal output out;

    component hash = Poseidon(2);
    
    hash.inputs[0] <== in[0];
    hash.inputs[1] <== in[1];

    out <== hash.out;
}

// if our hash is on the left side, we need the hash of the right branch, to create the hash of an upper level of the tree
// reference https://github.com/tornadocash/tornado-core/blob/master/circuits/merkleTree.circom
// if side == 0 returns [in[0], in[1]]
// if side == 1 returns [in[1], in[0]]
template ComplementaryNode() {
    signal input in[2];
    signal input side;
    signal output out[2];

    side * (1 - side) === 0;
    out[0] <== (in[1] - in[0])*side + in[0];
    out[1] <== (in[0] - in[1])*side + in[1];
}


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var hashers_count = 2**n - 1;
    // assuming n is a power of 2, there are n leaves and n/2 hashers for them
    var leaf_hashers_count = n / 2;

    // initate hasher components
    component hashers[hashers_count];

    var i;

    for (i=0; i < hashers_count; i++) {
        hashers[i] = HashTwo();
    }

    // feed leaves into hashers
    for (i=0; i < leaf_hashers_count; i++) {
        hashers[i].in[0] <== leaves[i*2];
        hashers[i].in[1] <== leaves[i*2+1];
    }
    
    // feed hashes of leaves into hashers until none remain, last hasher will output root
    var j = 0;
    for (i=leaf_hashers_count; i < hashers_count; i++) {
        hashers[i].in[0] <== hashers[j*2].out;
        hashers[i].in[1] <== hashers[j*2+1].out;
        j++;
    }

    // output root
    root <== hashers[hashers_count-1].out;
    
}

template MerkleTreeInclusionProof(n) {

    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //hashers will help us calculate the root with the leaf, path elements and path indices provided.
    component hashers[n];
    // selectors take care of choosing the right index for the complementary node of the leaf we choose
    component selectors[n];

    for (var i = 0; i < n; i++) {
        selectors[i] = ComplementaryNode();
        // starts with leaf, if not leaf take hash of previous tree level
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].out;

        selectors[i].in[1] <== path_elements[i];
        // we don't need % because it's not the real index, just an indication of the side that the node is on
        selectors[i].side <== path_index[i];


        hashers[i] = HashTwo();
        hashers[i].in[0] <== selectors[i].out[0];
        hashers[i].in[1] <== selectors[i].out[1];
    }

    root <== hashers[n - 1].out;
}
