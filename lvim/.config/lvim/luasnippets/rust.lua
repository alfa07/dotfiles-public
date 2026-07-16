return {
  s("bench.criterion.hashmap", {
    t {
      [=[use rand::thread_rng;]=],
      [=[use rand_distr::{Distribution, Normal, Uniform};]=],
      [=[use std::collections::HashMap;]=],
      [=[]=],
      [=[use criterion::black_box;]=],
      [=[use criterion::criterion_group;]=],
      [=[use criterion::criterion_main;]=],
      [=[use criterion::Criterion;]=],
      [=[]=],
      [=[fn bench_sequence(c: &mut Criterion) {]=],
      [=[    c.bench_function("bench_sequence", |b| {]=],
      [=[        let mut cache = HashMap::new();]=],
      [=[        b.iter(|| {]=],
      [=[            for i in 1..1000 {]=],
      [=[                let n = i % 100;]=],
      [=[                black_box(cache.insert(n, n));]=],
      [=[            }]=],
      [=[        });]=],
      [=[        b.iter(|| {]=],
      [=[            for i in 1..1000 {]=],
      [=[                let n = i % 100;]=],
      [=[                black_box(cache.get(&n));]=],
      [=[            }]=],
      [=[        });]=],
      [=[    });]=],
      [=[}]=],
      [=[]=],
      [=[fn bench_composite(c: &mut Criterion) {]=],
      [=[    c.bench_function("bench_composite", |b| {]=],
      [=[        let mut cache = HashMap::new();]=],
      [=[        let mut rng = thread_rng();]=],
      [=[        let uniform = Uniform::new(0, 100);]=],
      [=[        let mut rand_iter = uniform.sample_iter(&mut rng);]=],
      [=[        b.iter(|| {]=],
      [=[            for _ in 1..1000 {]=],
      [=[                let n = rand_iter.next().unwrap();]=],
      [=[                black_box(cache.insert(n, (vec![0u8; 12], n)));]=],
      [=[            }]=],
      [=[        });]=],
      [=[        b.iter(|| {]=],
      [=[            for _ in 1..1000 {]=],
      [=[                let n = rand_iter.next().unwrap();]=],
      [=[                black_box(cache.get(&n));]=],
      [=[            }]=],
      [=[        });]=],
      [=[    });]=],
      [=[}]=],
      [=[]=],
      [=[fn bench_composite_normal(c: &mut Criterion) {]=],
      [=[    // The cache size is ~ 1x sigma (stddev) to retain roughly >68% of records]=],
      [=[    const SIGMA: f64 = 50.0 / 3.0;]=],
      [=[]=],
      [=[    c.bench_function("bench_composite_normal", |b| {]=],
      [=[        let mut cache = HashMap::new();]=],
      [=[        // This should roughly cover all elements (within 3-sigma)]=],
      [=[        let mut rng = thread_rng();]=],
      [=[        let normal = Normal::new(50.0, SIGMA).unwrap();]=],
      [=[        let mut rand_iter = normal.sample_iter(&mut rng).map(|x| (x as u64) % 100);]=],
      [=[        b.iter(|| {]=],
      [=[            for _ in 1..1000 {]=],
      [=[                let n = rand_iter.next().unwrap();]=],
      [=[                black_box(cache.insert(n, (vec![0u8; 12], n)));]=],
      [=[            }]=],
      [=[        });]=],
      [=[        b.iter(|| {]=],
      [=[            for _ in 1..1000 {]=],
      [=[                let n = rand_iter.next().unwrap();]=],
      [=[                black_box(cache.get(&n));]=],
      [=[            }]=],
      [=[        });]=],
      [=[    });]=],
      [=[}]=],
      [=[]=],
      [=[criterion_group!(]=],
      [=[    benches,]=],
      [=[    bench_sequence,]=],
      [=[    bench_composite,]=],
      [=[    bench_composite_normal]=],
      [=[);]=],
      [=[criterion_main!(benches);]=],
    }
  }),
  s("idiom.print-hello-world", { t {
    [=[println!("Hello World");]=]
  } }),
  s("idiom.print-hello-10-times", { t {
    [=[for _ in 0..10 { println!("Hello"); }]=],
    [=[print!("{}", "Hello\n".repeat(10));]=]
  } }),
  s("idiom.create-a-procedure", { t {
    [=[fn finish(name : &str) {]=],
    [=[    println!("My job here is done. Goodbye {}", name);]=],
    [=[}]=]
  } }),
  s("idiom.create-a-function", { t {
    [=[fn square(x : u32) -> u32 { x * x }]=]
  } }),
  s("idiom.create-a-2d-point-data-structure", { t {
    [=[struct Point {]=],
    [=[    x: f64,]=],
    [=[    y: f64,]=],
    [=[}]=],
    [=[struct Point(f64, f64);]=]
  } }),
  s("idiom.iterate-over-list-values", { t {
    [=[for x in items {]=],
    [=[	do_something(x);]=],
    [=[}]=],
    [=[items.into_iter().for_each(|x| do_something(x));]=]
  } }),
  s("idiom.iterate-over-list-indexes-and-values", { t {
    [=[for (i, x) in items.iter().enumerate() {]=],
    [=[    println!("Item {} = {}", i, x);]=],
    [=[}]=],
    [=[items.iter().enumerate().for_each(|(i, x)| {]=],
    [=[    println!("Item {} = {}", i, x);]=],
    [=[})]=]
  } }),
  s("idiom.initialize-a-new-map-associative-array", { t {
    [=[use std::collections::BTreeMap;]=],
    [=[let mut x = BTreeMap::new();]=],
    [=[x.insert("one", 1);]=],
    [=[x.insert("two", 2);]=],
    [=[use std::collections::HashMap;]=],
    [=[let x: HashMap<&str, i32> = []=],
    [=[    ("one", 1),]=],
    [=[    ("two", 2),]=],
    [=[].into_iter().collect();]=]
  } }),
  s("idiom.create-a-binary-tree-data-structure", { t {
    [=[struct BinTree<T> {]=],
    [=[    value: T,]=],
    [=[    left: Option<Box<BinTree<T>>>,]=],
    [=[    right: Option<Box<BinTree<T>>>,]=],
    [=[}]=]
  } }),
  s("idiom.shuffle-a-list", { t {
    [=[extern crate rand;]=],
    [=[use rand::{Rng, StdRng};]=],
    [=[let mut rng = StdRng::new().unwrap();]=],
    [=[rng.shuffle(&mut x);]=],
    [=[use rand::seq::SliceRandom;]=],
    [=[use rand::thread_rng;]=],
    [=[let mut rng = thread_rng();]=],
    [=[x.shuffle(&mut rng);]=]
  } }),
  s("idiom.pick-a-random-element-from-a-list", { t {
    [=[use rand::{self, Rng};]=],
    [=[x[rand::thread_rng().gen_range(0..x.len())]]=],
    [=[use rand::seq::SliceRandom;]=],
    [=[let mut rng = rand::thread_rng();]=],
    [=[let choice = x.choose(&mut rng).unwrap();]=]
  } }),
  s("idiom.check-if-list-contains-a-value", { t {
    [=[list.contains(&x);]=],
    [=[list.iter().any(|v| v == &x)]=],
    [=[(&list).into_iter().any(|v| v == &x)]=]
  } }),
  s("idiom.iterate-over-map-keys-and-values", { t {
    [=[use std::collections::BTreeMap;]=],
    [=[for (k, x) in &mymap {]=],
    [=[    println!("Key={key}, Value={val}", key=k, val=x);]=],
    [=[}]=]
  } }),
  s("idiom.pick-uniformly-a-random-floating-point-number-in-a-b", { t {
    [=[extern crate rand;]=],
    [=[use rand::{Rng, thread_rng};]=],
    [=[thread_rng().gen_range(a..b);]=]
  } }),
  s("idiom.pick-uniformly-a-random-integer-in-a-b", { t {
    [=[extern crate rand;]=],
    [=[use rand::distributions::{IndependentSample, Range};]=],
    [=[fn pick(a: i32, b: i32) -> i32 {]=],
    [=[    let between = Range::new(a, b);]=],
    [=[    let mut rng = rand::thread_rng();]=],
    [=[    between.ind_sample(&mut rng)]=],
    [=[}]=],
    [=[]=],
    [=[use rand::distributions::Distribution;]=],
    [=[use rand::distributions::Uniform;]=],
    [=[Uniform::new_inclusive(a, b).sample(&mut rand::thread_rng())]=]
  } }),
  s("idiom.depth-first-traversal-of-a-binary-tree", { t {
    [=[struct BiTree<T> {]=],
    [=[    left: Option<Box<BiTree<T>>>,]=],
    [=[    right: Option<Box<BiTree<T>>>,]=],
    [=[    value: T,]=],
    [=[}]=],
    [=[fn depthFirstTraverse<T>(bt: &mut BiTree<T>, f: fn(&mut BiTree<T>)) {]=],
    [=[    if let Some(left) = &mut bt.left {]=],
    [=[        f(left);]=],
    [=[    }]=],
    [=[    ]=],
    [=[    f(bt);]=],
    [=[    ]=],
    [=[    if let Some(right) = &mut bt.right {]=],
    [=[        f(right);]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.create-a-tree-data-structure", { t {
    [=[struct Node<T> {]=],
    [=[  value: T,]=],
    [=[  children: Vec<Node<T>>,]=],
    [=[}]=]
  } }),
  s("idiom.depth-first-traversal-of-a-tree", { t {
    [=[pub struct Tree<V> {]=],
    [=[    children: Vec<Tree<V>>,]=],
    [=[    value: V]=],
    [=[}]=],
    [=[]=],
    [=[impl<V> Tree<V> {]=],
    [=[    pub fn dfs<F: Fn(&V)>(&self, f: F) {]=],
    [=[        self.dfs_helper(&f);]=],
    [=[    }]=],
    [=[    fn dfs_helper<F: Fn(&V)>(&self, f: &F) {]=],
    [=[        (f)(&self.value);]=],
    [=[        for child in &self.children {]=],
    [=[            child.dfs_helper(f)]=],
    [=[        }]=],
    [=[    }]=],
    [=[    // ...]=],
    [=[}]=]
  } }),
  s("idiom.reverse-a-list", { t {
    [=[let y: Vec<_> = x.into_iter().rev().collect();]=],
    [=[x.reverse();]=]
  } }),
  s("idiom.return-two-values", { t {
    [=[fn search<T: Eq>(m: &Vec<Vec<T>>, x: &T) -> Option<(usize, usize)> {]=],
    [=[    for (i, row) in m.iter().enumerate() {]=],
    [=[        for (j, column) in row.iter().enumerate() {]=],
    [=[            if *column == *x {]=],
    [=[                return Some((i, j));]=],
    [=[            }]=],
    [=[        }]=],
    [=[    }]=],
    [=[]=],
    [=[    None]=],
    [=[}]=]
  } }),
  s("idiom.swap-values", { t {
    [=[std::mem::swap(&mut a, &mut b);]=],
    [=[]=],
    [=[let (a, b) = (b, a);]=]
  } }),
  s("idiom.convert-string-to-integer", { t {
    [=[let i = s.parse::<i32>().unwrap();]=],
    [=[let i: i32 = s.parse().unwrap_or(0);]=],
    [=[let i = match s.parse::<i32>() {]=],
    [=[  Ok(i) => i,]=],
    [=[  Err(_e) => -1,]=],
    [=[};]=]
  } }),
  s("idiom.convert-real-number-to-string-with-2-decimal-places", { t {
    [=[let s = format!("{:.2}", x);]=]
  } }),
  s("idiom.assign-to-string-the-japanese-word", { t {
    [=[let s = "ネコ";]=]
  } }),
  s("idiom.send-a-value-to-another-thread", { t {
    [=[use std::thread;]=],
    [=[use std::sync::mpsc::channel;]=],
    [=[let (send, recv) = channel();]=],
    [=[]=],
    [=[thread::spawn(move || {]=],
    [=[    loop {]=],
    [=[        let msg = recv.recv().unwrap();]=],
    [=[        println!("Hello, {:?}", msg);]=],
    [=[    }  ]=],
    [=[});]=],
    [=[]=],
    [=[send.send("Alan").unwrap();]=]
  } }),
  s("idiom.create-a-2-dimensional-array", { t {
    [=[let mut x = vec![vec![0.0f64; N]; M];]=],
    [=[let mut x = [[0.0; N] ; M];]=]
  } }),
  s("idiom.create-a-3-dimensional-array", { t {
    [=[let x = vec![vec![vec![0.0f64; p]; n]; m];]=],
    [=[let x = [[[0.0f64; P]; N]; M];]=]
  } }),
  s("idiom.sort-by-a-property", { t {
    [=[items.sort_by(|a,b| a.p.cmp(&b.p));]=],
    [=[items.sort_by_key(|x| x.p);]=]
  } }),
  s("idiom.remove-item-from-list-by-its-index", { t {
    [=[items.remove(i)]=]
  } }),
  s("idiom.parallelize-execution-of-1000-independent-tasks", { t {
    [=[use std::thread;]=],
    [=[let threads: Vec<_> = (0..1000).map(|i| {]=],
    [=[	thread::spawn(move || f(i))]=],
    [=[}).collect();]=],
    [=[]=],
    [=[for thread in threads {]=],
    [=[	thread.join();]=],
    [=[}]=],
    [=[extern crate rayon;]=],
    [=[use rayon::prelude::*;]=],
    [=[(0..1000).into_par_iter().for_each(f);]=]
  } }),
  s("idiom.recursive-factorial-simple", { t {
    [=[fn f(n: u32) -> u32 {]=],
    [=[    if n < 2 {]=],
    [=[        1]=],
    [=[    } else {]=],
    [=[        n * f(n - 1)]=],
    [=[    }]=],
    [=[}]=],
    [=[fn factorial(num: u64) -> u64 {]=],
    [=[    match num {]=],
    [=[        0 | 1 => 1,]=],
    [=[        _ => factorial(num - 1) * num,]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.integer-exponentiation-by-squaring", { t {
    [=[fn exp(x: u64, n: u64) -> u64 {]=],
    [=[    match n {]=],
    [=[        0 => 1,]=],
    [=[        1 => x,]=],
    [=[        i if i % 2 == 0 => exp(x * x, n / 2),]=],
    [=[        _ => x * exp(x * x, (n - 1) / 2),]=],
    [=[    }     ]=],
    [=[}]=],
    [=[fn exp(x: u64, n: u32) -> u64 {]=],
    [=[    x.pow(n)]=],
    [=[}]=]
  } }),
  s("idiom.atomically-read-and-update-variable", { t {
    [=[let mut x = x.lock().unwrap();]=],
    [=[*x = f(x);]=]
  } }),
  s("idiom.create-a-set-of-objects", { t {
    [=[use std::collections::HashSet;]=],
    [=[let x: HashSet<T> = HashSet::new();]=]
  } }),
  s("idiom.first-class-function-compose", { t {
    [=[fn compose<'a, A, B, C, G, F>(f: F, g: G) -> Box<Fn(A) -> C + 'a>]=],
    [=[	where F: 'a + Fn(A) -> B, G: 'a + Fn(B) -> C]=],
    [=[{]=],
    [=[	Box::new(move |x| g(f(x)))]=],
    [=[}]=],
    [=[fn compose<A, B, C>(f: impl Fn(A) -> B, g: impl Fn(B) -> C) -> impl Fn(A) -> C {]=],
    [=[    move |x| g(f(x))]=],
    [=[}]=]
  } }),
  s("idiom.first-class-function-generic-composition", { t {
    [=[fn compose<'a, A, B, C, G, F>(f: F, g: G) -> Box<Fn(A) -> C + 'a>]=],
    [=[	where F: 'a + Fn(A) -> B, G: 'a + Fn(B) -> C]=],
    [=[{]=],
    [=[	Box::new(move |x| g(f(x)))]=],
    [=[}]=],
    [=[fn compose<A, B, C>(f: impl Fn(A) -> B, g: impl Fn(B) -> C) -> impl Fn(A) -> C {]=],
    [=[    move |x| g(f(x))]=],
    [=[}]=]
  } }),
  s("idiom.currying", { t {
    [=[fn add(a: u32, b: u32) -> u32 {]=],
    [=[    a + b]=],
    [=[}]=],
    [=[]=],
    [=[let add5 = move |x| add(5, x);]=],
    [=[ ]=]
  } }),
  s("idiom.extract-a-substring", { t {
    [=[extern crate unicode_segmentation;]=],
    [=[use unicode_segmentation::UnicodeSegmentation;]=],
    [=[let t = s.graphemes(true).skip(i).take(j - i).collect::<String>();]=],
    [=[use substring::Substring;]=],
    [=[let t = s.substring(i, j);]=]
  } }),
  s("idiom.check-if-string-contains-a-word", { t {
    [=[let ok = s.contains(word);]=]
  } }),
  s("idiom.reverse-a-string", { t {
    [=[let t = s.chars().rev().collect::<String>();]=],
    [=[let t: String = s.chars().rev().collect();]=]
  } }),
  s("idiom.continue-outer-loop", { t {
    [=['outer: for va in &a {]=],
    [=[    for vb in &b {]=],
    [=[        if va == vb {]=],
    [=[            continue 'outer;]=],
    [=[        }]=],
    [=[    }]=],
    [=[    println!("{}", va);]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.break-outer-loop", { t {
    [=['outer: for v in m {]=],
    [=[    'inner: for i in v {]=],
    [=[        if i < 0 {]=],
    [=[            println!("Found {}", i);]=],
    [=[            break 'outer;]=],
    [=[        }]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.insert-element-in-list", { t {
    [=[s.insert(i, x);]=]
  } }),
  s("idiom.pause-execution-for-5-seconds", { t {
    [=[use std::{thread, time};]=],
    [=[thread::sleep(time::Duration::from_secs(5));]=]
  } }),
  s("idiom.extract-beginning-of-string-prefix", { t {
    [=[let t = s.char_indices().nth(5).map_or(s, |(i, _)| &s[..i]);]=],
    [=[let t = s.chars().take(5).collect::<String>();]=]
  } }),
  s("idiom.extract-string-suffix", { t {
    [=[let last5ch = s.chars().count() - 5;]=],
    [=[let t: String = s.chars().skip(last5ch).collect();]=],
    [=[]=]
  } }),
  s("idiom.multi-line-string-literal", { t {
    [=[let s = "line 1]=],
    [=[line 2]=],
    [=[line 3";]=],
    [=[let s = r#"Huey]=],
    [=[Dewey]=],
    [=[Louie"#;]=]
  } }),
  s("idiom.split-a-space-separated-string", { t {
    [=[let chunks: Vec<_> = s.split_whitespace().collect();]=],
    [=[let chunks: Vec<_> = s.split_ascii_whitespace().collect();]=],
    [=[let chunks: Vec<_> = s.split(' ').collect();]=]
  } }),
  s("idiom.make-an-infinite-loop", { t {
    [=[loop {]=],
    [=[	// Do something]=],
    [=[}]=]
  } }),
  s("idiom.check-if-map-contains-key", { t {
    [=[use std::collections::HashMap;]=],
    [=[m.contains_key(&k)]=]
  } }),
  s("idiom.check-if-map-contains-value", { t {
    [=[use std::collections::BTreeMap;]=],
    [=[let does_contain = m.values().any(|&val| *val == v);]=]
  } }),
  s("idiom.join-a-list-of-strings", { t {
    [=[let y = x.join(", ");]=]
  } }),
  s("idiom.compute-sum-of-integers", { t {
    [=[x.iter().sum()]=],
    [=[let s = x.iter().sum::<i32>();]=]
  } }),
  s("idiom.convert-integer-to-string", { t {
    [=[let s = i.to_string();]=],
    [=[let s = format!("{}", i);]=]
  } }),
  s("idiom.launch-1000-parallel-tasks-and-wait-for-completion", { t {
    [=[use std::thread;]=],
    [=[let threads: Vec<_> = (0..1000).map(|i| thread::spawn(move || f(i))).collect();]=],
    [=[]=],
    [=[for t in threads {]=],
    [=[	t.join();]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.filter-list", { t {
    [=[let y: Vec<_> = x.iter().filter(p).collect();]=]
  } }),
  s("idiom.extract-file-content-to-a-string", { t {
    [=[use std::io::prelude::*;]=],
    [=[use std::fs::File;]=],
    [=[let mut file = File::open(f)?;]=],
    [=[let mut lines = String::new();]=],
    [=[file.read_to_string(&mut lines)?;]=],
    [=[use std::fs;]=],
    [=[let lines = fs::read_to_string(f).expect("Can't read file.");]=]
  } }),
  s("idiom.write-to-standard-error-stream", { t {
    [=[eprintln!("{} is negative", x);]=]
  } }),
  s("idiom.read-command-line-argument", { t {
    [=[use std::env;]=],
    [=[let first_arg = env::args().skip(1).next();]=],
    [=[]=],
    [=[let fallback = "".to_owned();]=],
    [=[let x = first_arg.unwrap_or(fallback);]=],
    [=[use std::env;]=],
    [=[let x = env::args().nth(1).unwrap_or("".to_string());]=]
  } }),
  s("idiom.get-current-date", { t {
    [=[extern crate time;]=],
    [=[let d = time::now();]=],
    [=[use std::time::SystemTime;]=],
    [=[let d = SystemTime::now();]=]
  } }),
  s("idiom.find-substring-position", { t {
    [=[let i = x.find(y);]=]
  } }),
  s("idiom.replace-fragment-of-a-string", { t {
    [=[let x2 = x.replace(&y, &z);]=]
  } }),
  s("idiom.big-integer-value-3-power-247", { t {
    [=[extern crate num;]=],
    [=[use num::bigint::ToBigInt;]=],
    [=[let a = 3.to_bigint().unwrap();]=],
    [=[let x = num::pow(a, 247);]=]
  } }),
  s("idiom.format-decimal-number", { t {
    [=[let s = format!("{:.1}%", 100.0 * x);]=]
  } }),
  s("idiom.big-integer-exponentiation", { t {
    [=[extern crate num;]=],
    [=[let z = num::pow(x, n);]=]
  } }),
  s("idiom.binomial-coefficient-n-choose-k", { t {
    [=[extern crate num;]=],
    [=[]=],
    [=[use num::bigint::BigInt;]=],
    [=[use num::bigint::ToBigInt;]=],
    [=[use num::traits::One;]=],
    [=[fn binom(n: u64, k: u64) -> BigInt {]=],
    [=[    let mut res = BigInt::one();]=],
    [=[    for i in 0..k {]=],
    [=[        res = (res * (n - i).to_bigint().unwrap()) /]=],
    [=[              (i + 1).to_bigint().unwrap();]=],
    [=[    }]=],
    [=[    res]=],
    [=[}]=]
  } }),
  s("idiom.create-a-bitset", { t {
    [=[let mut x = vec![false; n];]=]
  } }),
  s("idiom.seed-random-generator", { t {
    [=[use rand::{Rng, SeedableRng, rngs::StdRng};]=],
    [=[let s = 32;]=],
    [=[let mut rng = StdRng::seed_from_u64(s);]=]
  } }),
  s("idiom.use-clock-as-random-generator-seed", { t {
    [=[use rand::{Rng, SeedableRng, rngs::StdRng};]=],
    [=[use std::time::SystemTime;]=],
    [=[let d = SystemTime::now()]=],
    [=[    .duration_since(SystemTime::UNIX_EPOCH)]=],
    [=[    .expect("Duration since UNIX_EPOCH failed");]=],
    [=[let mut rng = StdRng::seed_from_u64(d.as_secs());]=]
  } }),
  s("idiom.echo-program-implementation", { t {
    [=[use std::env;]=],
    [=[println!("{}", env::args().skip(1).collect::<Vec<_>>().join(" "));]=],
    [=[use itertools::Itertools;]=],
    [=[println!("{}", std::env::args().skip(1).format(" "));]=]
  } }),
  s("idiom.compute-gcd", { t {
    [=[extern crate num;]=],
    [=[]=],
    [=[use num::Integer;]=],
    [=[use num::bigint::BigInt;]=],
    [=[let x = a.gcd(&b);]=]
  } }),
  s("idiom.compute-lcm", { t {
    [=[extern crate num;]=],
    [=[]=],
    [=[use num::Integer;]=],
    [=[use num::bigint::BigInt;]=],
    [=[let x = a.lcm(&b);]=]
  } }),
  s("idiom.binary-digits-from-an-integer", { t {
    [=[let s = format!("{:b}", x);]=],
    [=[let s = format!("{x:b}");]=]
  } }),
  s("idiom.complex-number", { t {
    [=[extern crate num;]=],
    [=[use num::Complex;]=],
    [=[let mut x = Complex::new(-2, 3);]=],
    [=[x *= Complex::i();]=]
  } }),
  s("idiom.do-while-loop", { t {
    [=[loop {]=],
    [=[    doStuff();]=],
    [=[    if !c { break; }]=],
    [=[}]=],
    [=[while {]=],
    [=[   doStuff();]=],
    [=[   c]=],
    [=[} { /* EMPTY */ }]=]
  } }),
  s("idiom.convert-integer-to-floating-point-number", { t {
    [=[let y = x as f64;]=]
  } }),
  s("idiom.truncate-floating-point-number-to-integer", { t {
    [=[let y = x as i32;]=]
  } }),
  s("idiom.round-floating-point-number-to-integer", { t {
    [=[let y = x.round() as i64;]=]
  } }),
  s("idiom.count-substring-occurrences", { t {
    [=[let c = s.matches(t).count();]=]
  } }),
  s("idiom.regex-with-character-repetition", { t {
    [=[extern crate regex;]=],
    [=[use regex::Regex;]=],
    [=[let r = Regex::new(r"htt+p").unwrap();]=]
  } }),
  s("idiom.count-bits-set-in-integer-binary-representation", { t {
    [=[let c = i.count_ones();]=]
  } }),
  s("idiom.check-if-integer-addition-will-overflow", { t {
    [=[fn adding_will_overflow(x: usize, y: usize) -> bool {]=],
    [=[    x.checked_add(y).is_none()]=],
    [=[}]=]
  } }),
  s("idiom.check-if-integer-multiplication-will-overflow", { t {
    [=[fn multiply_will_overflow(x: i64, y: i64) -> bool {]=],
    [=[    x.checked_mul(y).is_none()]=],
    [=[}]=]
  } }),
  s("idiom.stop-program", { t {
    [=[std::process::exit(0);]=]
  } }),
  s("idiom.allocate-1m-bytes", { t {
    [=[let buf: Vec<u8> = Vec::with_capacity(1000000);]=]
  } }),
  s("idiom.handle-invalid-argument", { t {
    [=[enum CustomError { InvalidAnswer }]=],
    [=[]=],
    [=[fn do_stuff(x: i32) -> Result<i32, CustomError> {]=],
    [=[    if x != 42 {]=],
    [=[        Err(CustomError::InvalidAnswer)]=],
    [=[    } else {]=],
    [=[        Ok(x)]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.read-only-outside", { t {
    [=[struct Foo {]=],
    [=[    x: usize]=],
    [=[}]=],
    [=[]=],
    [=[impl Foo {]=],
    [=[    pub fn new(x: usize) -> Self {]=],
    [=[        Foo { x }]=],
    [=[    }]=],
    [=[]=],
    [=[    pub fn x<'a>(&'a self) -> &'a usize {]=],
    [=[        &self.x]=],
    [=[    }]=],
    [=[]=],
    [=[    pub fn bar(&mut self) {]=],
    [=[        self.x += 1;]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.load-json-file-into-object", { t {
    [=[#[macro_use] extern crate serde_derive;]=],
    [=[extern crate serde_json;]=],
    [=[use std::fs::File;]=],
    [=[let x = ::serde_json::from_reader(File::open("data.json")?)?;]=]
  } }),
  s("idiom.save-object-into-json-file", { t {
    [=[extern crate serde_json;]=],
    [=[#[macro_use] extern crate serde_derive;]=],
    [=[]=],
    [=[use std::fs::File;]=],
    [=[::serde_json::to_writer(&File::create("data.json")?, &x)?]=]
  } }),
  s("idiom.pass-a-runnable-procedure-as-parameter", { t {
    [=[fn control(f: impl Fn()) {]=],
    [=[    f();]=],
    [=[}]=]
  } }),
  s("idiom.print-the-type-of-a-variable", { t {
    [=[#![feature(core_intrinsics)]]=],
    [=[fn type_of<T>(_: &T) -> &'static str {]=],
    [=[    std::intrinsics::type_name::<T>()]=],
    [=[}]=],
    [=[]=],
    [=[println!("{}", type_of(&x));]=]
  } }),
  s("idiom.get-file-size", { t {
    [=[use std::fs;]=],
    [=[let x = fs::metadata(path)?.len();]=],
    [=[let x = path.metadata()?.len();]=]
  } }),
  s("idiom.check-string-prefix", { t {
    [=[let b = s.starts_with(prefix);]=]
  } }),
  s("idiom.check-string-suffix", { t {
    [=[let b = s.ends_with(suffix);]=]
  } }),
  s("idiom.epoch-seconds-to-date-object", { t {
    [=[extern crate chrono;]=],
    [=[use chrono::prelude::*;]=],
    [=[let d = NaiveDateTime::from_timestamp(ts, 0);]=]
  } }),
  s("idiom.format-date-yyyy-mm-dd", { t {
    [=[extern crate chrono;]=],
    [=[use chrono::prelude::*;]=],
    [=[Utc::today().format("%Y-%m-%d")]=],
    [=[use time::macros::format_description;]=],
    [=[let format = format_description!("[year]-[month]-[day]");]=],
    [=[let x = d.format(&format).expect("Failed to format the date");]=]
  } }),
  s("idiom.sort-by-a-comparator", { t {
    [=[items.sort_by(c);]=]
  } }),
  s("idiom.load-from-http-get-request-into-a-string", { t {
    [=[extern crate reqwest;]=],
    [=[use reqwest::Client;]=],
    [=[let client = Client::new();]=],
    [=[let s = client.get(u).send().and_then(|res| res.text())?;]=],
    [=[[dependencies]]=],
    [=[ureq = "1.0"]=],
    [=[let s = ureq::get(u).call().into_string()?;]=],
    [=[[dependencies]]=],
    [=[error-chain = "0.12.4"]=],
    [=[reqwest = { version = "0.11.2", features = ["blocking"] }]=],
    [=[]=],
    [=[use error_chain::error_chain;]=],
    [=[use std::io::Read;]=],
    [=[let mut response = reqwest::blocking::get(u)?;]=],
    [=[let mut s = String::new();]=],
    [=[response.read_to_string(&mut s)?;]=]
  } }),
  s("idiom.load-from-http-get-request-into-a-file", { t {
    [=[extern crate reqwest;]=],
    [=[use reqwest::Client;]=],
    [=[use std::fs::File;]=],
    [=[let client = Client::new();]=],
    [=[match client.get(&u).send() {]=],
    [=[    Ok(res) => {]=],
    [=[        let file = File::create("result.txt")?;]=],
    [=[        ::std::io::copy(res, file)?;]=],
    [=[    },]=],
    [=[    Err(e) => eprintln!("failed to send request: {}", e),]=],
    [=[};]=]
  } }),
  s("idiom.current-executable-name", { t {
    [=[fn get_exec_name() -> Option<String> {]=],
    [=[    std::env::current_exe()]=],
    [=[        .ok()]=],
    [=[        .and_then(|pb| pb.file_name().map(|s| s.to_os_string()))]=],
    [=[        .and_then(|s| s.into_string().ok())]=],
    [=[}]=],
    [=[]=],
    [=[fn main() -> () {]=],
    [=[    let s = get_exec_name().unwrap();]=],
    [=[    println!("{}", s);]=],
    [=[}]=],
    [=[let s = std::env::current_exe()]=],
    [=[    .expect("Can't get the exec path")]=],
    [=[    .file_name()]=],
    [=[    .expect("Can't get the exec name")]=],
    [=[    .to_string_lossy()]=],
    [=[    .into_owned();]=]
  } }),
  s("idiom.get-program-working-directory", { t {
    [=[use std::env;]=],
    [=[let dir = env::current_dir().unwrap();]=]
  } }),
  s("idiom.get-folder-containing-current-program", { t {
    [=[let dir = std::env::current_exe()?]=],
    [=[    .canonicalize()]=],
    [=[    .expect("the current exe should exist")]=],
    [=[    .parent()]=],
    [=[    .expect("the current exe should be a file")]=],
    [=[    .to_string_lossy()]=],
    [=[    .to_owned();]=]
  } }),
  s("idiom.number-of-bytes-of-a-type", { t {
    [=[let n = ::std::mem::size_of::<T>();]=]
  } }),
  s("idiom.check-if-string-is-blank", { t {
    [=[let blank = s.trim().is_empty();]=],
    [=[let blank = s.chars().all(|c| c.is_whitespace());]=]
  } }),
  s("idiom.launch-other-program", { t {
    [=[use std::process::Command;]=],
    [=[let output = Command::new("x")]=],
    [=[    .args(&["a", "b"])]=],
    [=[    .spawn()]=],
    [=[    .expect("failed to execute process");]=],
    [=[use std::process::Command;]=],
    [=[let output = Command::new("x")]=],
    [=[        .args(&["a", "b"])]=],
    [=[        .output()]=],
    [=[        .expect("failed to execute process");]=],
    [=[use std::process::Command;]=],
    [=[let output = Command::new("x")]=],
    [=[        .args(&["a", "b"])]=],
    [=[        .status()]=],
    [=[        .expect("failed to execute process");]=]
  } }),
  s("idiom.iterate-over-map-entries-ordered-by-keys", { t {
    [=[for (k, x) in mymap {]=],
    [=[    println!("({}, {})", k, x);]=],
    [=[}]=]
  } }),
  s("idiom.iterate-over-map-entries-ordered-by-values", { t {
    [=[use itertools::Itertools;]=],
    [=[for (k, x) in mymap.iter().sorted_by_key(|x| x.1) {]=],
    [=[	println!("[{},{}]", k, x);]=],
    [=[}]=],
    [=[let mut items: Vec<_> = mymap.iter().collect();]=],
    [=[items.sort_by_key(|item| item.1);]=],
    [=[for (k, x) in items {]=],
    [=[    println!("[{},{}]", k, x);]=],
    [=[}]=]
  } }),
  s("idiom.test-deep-equality", { t {
    [=[let b = x == y;]=]
  } }),
  s("idiom.compare-dates", { t {
    [=[extern crate chrono;]=],
    [=[use chrono::prelude::*;]=],
    [=[let b = d1 < d2;]=]
  } }),
  s("idiom.remove-occurrences-of-word-from-string", { t {
    [=[s2 = s1.replace(w, "");]=],
    [=[let s2 = str::replace(s1, w, "");]=]
  } }),
  s("idiom.get-list-size", { t {
    [=[let n = x.len();]=],
    [=[]=],
    [=[]=]
  } }),
  s("idiom.list-to-set", { t {
    [=[use std::collections::HashSet;]=],
    [=[let y: HashSet<_> = x.into_iter().collect();]=]
  } }),
  s("idiom.deduplicate-list", { t {
    [=[x.sort();]=],
    [=[x.dedup();]=],
    [=[use itertools::Itertools;]=],
    [=[let dedup: Vec<_> = x.iter().unique().collect();]=]
  } }),
  s("idiom.read-integer-from-stdin", { t {
    [=[fn get_input() -> String {]=],
    [=[    let mut buffer = String::new();]=],
    [=[    std::io::stdin().read_line(&mut buffer).expect("Failed");]=],
    [=[    buffer]=],
    [=[}]=],
    [=[]=],
    [=[let n = get_input().trim().parse::<i64>().unwrap();]=],
    [=[use std::io;]=],
    [=[let mut input = String::new();]=],
    [=[io::stdin().read_line(&mut input).unwrap();]=],
    [=[let n: i32 = input.trim().parse().unwrap();]=],
    [=[use std::io::BufRead;]=],
    [=[let n: i32 = std::io::stdin()]=],
    [=[    .lock()]=],
    [=[    .lines()]=],
    [=[    .next()]=],
    [=[    .expect("stdin should be available")]=],
    [=[    .expect("couldn't read from stdin")]=],
    [=[    .trim()]=],
    [=[    .parse()]=],
    [=[    .expect("input was not an integer");]=],
    [=[#[macro_use] extern crate text_io;]=],
    [=[let n: i32 = read!();]=],
    [=[]=]
  } }),
  s("idiom.udp-listen-and-read", { t {
    [=[use std::net::UdpSocket;]=],
    [=[let mut b = [0 as u8; 1024];]=],
    [=[let sock = UdpSocket::bind(("localhost", p)).unwrap();]=],
    [=[sock.recv_from(&mut b).unwrap();]=]
  } }),
  s("idiom.declare-an-enumeration", { t {
    [=[enum Suit {]=],
    [=[    Spades,]=],
    [=[    Hearts,]=],
    [=[    Diamonds,]=],
    [=[    Clubs,]=],
    [=[}]=]
  } }),
  s("idiom.assert-condition", { t {
    [=[assert!(is_consistent);]=]
  } }),
  s("idiom.binary-search-for-a-value-in-sorted-array", { t {
    [=[a.binary_search(&x).unwrap_or(-1);]=]
  } }),
  s("idiom.measure-function-call-duration", { t {
    [=[use std::time::{Duration, Instant};]=],
    [=[let start = Instant::now();]=],
    [=[foo();]=],
    [=[let duration = start.elapsed();]=],
    [=[println!("{}", duration);]=],
    [=[]=]
  } }),
  s("idiom.multiple-return-values", { t {
    [=[fn foo() -> (String, bool) {]=],
    [=[    (String::from("bar"), true)]=],
    [=[}]=]
  } }),
  s("idiom.source-code-inclusion", { t {
    [=[fn main() {]=],
    [=[    include!("foobody.txt");]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.breadth-first-traversing-of-a-tree", { t {
    [=[use std::collections::VecDeque;]=],
    [=[struct Tree<V> {]=],
    [=[    children: Vec<Tree<V>>,]=],
    [=[    value: V]=],
    [=[}]=],
    [=[]=],
    [=[impl<V> Tree<V> {]=],
    [=[    fn bfs(&self, f: impl Fn(&V)) {]=],
    [=[        let mut q = VecDeque::new();]=],
    [=[        q.push_back(self);]=],
    [=[]=],
    [=[        while let Some(t) = q.pop_front() {]=],
    [=[            (f)(&t.value);]=],
    [=[            for child in &t.children {]=],
    [=[                q.push_back(child);]=],
    [=[            }]=],
    [=[        }]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.breadth-first-traversal-in-a-graph", { t {
    [=[use std::rc::{Rc, Weak};]=],
    [=[use std::cell::RefCell;]=],
    [=[struct Vertex<V> {]=],
    [=[	value: V,]=],
    [=[	neighbours: Vec<Weak<RefCell<Vertex<V>>>>,]=],
    [=[}]=],
    [=[]=],
    [=[// ...]=],
    [=[]=],
    [=[fn bft(start: Rc<RefCell<Vertex<V>>>, f: impl Fn(&V)) {]=],
    [=[	let mut q = vec![start];]=],
    [=[	let mut i = 0;]=],
    [=[	while i < q.len() {]=],
    [=[	    let v = Rc::clone(&q[i]);]=],
    [=[	    i += 1;]=],
    [=[	    (f)(&v.borrow().value);]=],
    [=[	    for n in &v.borrow().neighbours {]=],
    [=[	        let n = n.upgrade().expect("Invalid neighbour");]=],
    [=[	        if q.iter().all(|v| v.as_ptr() != n.as_ptr()) {]=],
    [=[	            q.push(n);]=],
    [=[	        }]=],
    [=[	    }]=],
    [=[	}]=],
    [=[}]=]
  } }),
  s("idiom.depth-first-traversal-in-a-graph", { t {
    [=[use std::rc::{Rc, Weak};]=],
    [=[use std::cell::RefCell;]=],
    [=[struct Vertex<V> {]=],
    [=[	value: V,]=],
    [=[	neighbours: Vec<Weak<RefCell<Vertex<V>>>>,]=],
    [=[}]=],
    [=[]=],
    [=[// ...]=],
    [=[]=],
    [=[fn dft_helper(start: Rc<RefCell<Vertex<V>>>, f: &impl Fn(&V), s: &mut Vec<*const Vertex<V>>) {]=],
    [=[	s.push(start.as_ptr());]=],
    [=[	(f)(&start.borrow().value);]=],
    [=[	for n in &start.borrow().neighbours {]=],
    [=[		let n = n.upgrade().expect("Invalid neighbor");]=],
    [=[		if s.iter().all(|&p| p != n.as_ptr()) {]=],
    [=[			Self::dft_helper(n, f, s);]=],
    [=[		}]=],
    [=[	}]=],
    [=[}]=]
  } }),
  s("idiom.successive-conditions", { t {
    [=[if c1 { f1() } else if c2 { f2() } else if c3 { f3() }]=],
    [=[match true {]=],
    [=[    _ if c1 => f1(),]=],
    [=[    _ if c2 => f2(),]=],
    [=[    _ if c3 => f3(),]=],
    [=[    _ => (),]=],
    [=[}]=]
  } }),
  s("idiom.measure-duration-of-procedure-execution", { t {
    [=[use std::time::Instant;]=],
    [=[let start = Instant::now();]=],
    [=[f();]=],
    [=[let duration = start.elapsed();]=]
  } }),
  s("idiom.case-insensitive-string-contains", { t {
    [=[extern crate regex;]=],
    [=[use regex::Regex;]=],
    [=[let re = Regex::new(&format!("(?i){}", regex::escape(word))).unwrap();]=],
    [=[let ok = re.is_match(&s);]=],
    [=[extern crate regex;]=],
    [=[use regex::RegexBuilder;]=],
    [=[let re =]=],
    [=[    RegexBuilder::new(&regex::escape(word))]=],
    [=[    .case_insensitive(true)]=],
    [=[    .build().unwrap();]=],
    [=[]=],
    [=[let ok = re.is_match(s);]=],
    [=[let ok = s.to_ascii_lowercase().contains(&word.to_ascii_lowercase());]=]
  } }),
  s("idiom.create-a-new-list", { t {
    [=[let items = vec![a, b, c];]=]
  } }),
  s("idiom.remove-item-from-list-by-its-value", { t {
    [=[if let Some(i) = items.first(&x) {]=],
    [=[    items.remove(i);]=],
    [=[}]=]
  } }),
  s("idiom.remove-all-occurrences-of-a-value-from-a-list", { t {
    [=[items = items.into_iter().filter(|&item| item != x).collect();]=],
    [=[items.retain(|&item| item != x);]=]
  } }),
  s("idiom.check-if-string-contains-only-digits", { t {
    [=[let chars_are_numeric: Vec<bool> = s.chars()]=],
    [=[				.map(|c|c.is_numeric())]=],
    [=[				.collect();]=],
    [=[let b = !chars_are_numeric.contains(&false);]=],
    [=[let b = s.chars().all(char::is_numeric);]=],
    [=[let b = s.bytes().all(|c| c.is_ascii_digit());]=]
  } }),
  s("idiom.create-temp-file", { t {
    [=[use tempdir::TempDir;]=],
    [=[use std::fs::File;]=],
    [=[let temp_dir = TempDir::new("prefix")?;]=],
    [=[let temp_file = File::open(temp_dir.path().join("file_name"))?;]=]
  } }),
  s("idiom.create-temp-directory", { t {
    [=[extern crate tempdir;]=],
    [=[use tempdir::TempDir;]=],
    [=[let tmp = TempDir::new("prefix")?;]=]
  } }),
  s("idiom.delete-map-entry", { t {
    [=[use std::collections::HashMap;]=],
    [=[m.remove(&k);]=]
  } }),
  s("idiom.iterate-in-sequence-over-two-lists", { t {
    [=[for i in item1.iter().chain(item2.iter()) {]=],
    [=[    print!("{} ", i);]=],
    [=[}]=]
  } }),
  s("idiom.hexadecimal-digits-of-an-integer", { t {
    [=[let s = format!("{:X}", x);]=]
  } }),
  s("idiom.iterate-alternatively-over-two-lists", { t {
    [=[extern crate itertools;]=],
    [=[for pair in izip!(&items1, &items2) {]=],
    [=[    println!("{}", pair.0);]=],
    [=[    println!("{}", pair.1);]=],
    [=[}]=]
  } }),
  s("idiom.check-if-file-exists", { t {
    [=[let b = std::path::Path::new(fp).exists();]=],
    [=[]=]
  } }),
  s("idiom.print-log-line-with-datetime", { t {
    [=[eprintln!("[{}] {}", humantime::format_rfc3339_seconds(std::time::SystemTime::now()), msg);]=]
  } }),
  s("idiom.convert-string-to-floating-point-number", { t {
    [=[let f = s.parse::<f32>().unwrap();]=],
    [=[let f: f32 = s.parse().unwrap();]=]
  } }),
  s("idiom.remove-all-non-ascii-characters", { t {
    [=[let t = s.replace(|c: char| !c.is_ascii(), "");]=],
    [=[let t = s.chars().filter(|c| c.is_ascii()).collect::<String>();]=]
  } }),
  s("idiom.read-list-of-integers-from-stdin", { t {
    [=[use std::{]=],
    [=[    io::{self, Read},]=],
    [=[    str::FromStr,]=],
    [=[}]=],
    [=[let mut string = String::new();]=],
    [=[io::stdin().read_to_string(&mut string)?;]=],
    [=[let result = string]=],
    [=[    .lines()]=],
    [=[    .map(i32::from_str)]=],
    [=[    .collect::<Result<Vec<_>, _>>();]=]
  } }),
  s("idiom.remove-trailing-slash", { t {
    [=[if p.ends_with('/') { p.pop(); }]=]
  } }),
  s("idiom.remove-string-trailing-path-separator", { t {
    [=[let p = if ::std::path::is_separator(p.chars().last().unwrap()) {]=],
    [=[    &p[0..p.len()-1]]=],
    [=[} else {]=],
    [=[    p]=],
    [=[};]=],
    [=[p = p.strip_suffix(std::path::is_separator).unwrap_or(p);]=]
  } }),
  s("idiom.turn-a-character-into-a-string", { t {
    [=[let s = c.to_string();]=]
  } }),
  s("idiom.concatenate-string-with-integer", { t {
    [=[let t = format!("{}{}", s, i);]=],
    [=[// or]=],
    [=[let t = format!("{s}{i}");]=]
  } }),
  s("idiom.halfway-between-two-hex-color-codes", { t {
    [=[use std::str::FromStr;]=],
    [=[use std::fmt;]=],
    [=["Too long for text box, see online demo"]=]
  } }),
  s("idiom.delete-file", { t {
    [=[use std::fs;]=],
    [=[let r = fs::remove_file(filepath);]=]
  } }),
  s("idiom.format-integer-with-zero-padding", { t {
    [=[let s = format!("{:03}", i);]=]
  } }),
  s("idiom.declare-constant-string", { t {
    [=[const PLANET: &str = "Earth";]=]
  } }),
  s("idiom.random-sublist", { t {
    [=[use rand::prelude::*;]=],
    [=[let mut rng = &mut rand::thread_rng();]=],
    [=[let y = x.choose_multiple(&mut rng, k).cloned().collect::<Vec<_>>();]=]
  } }),
  s("idiom.trie", { t {
    [=[struct Trie {]=],
    [=[    val: String,]=],
    [=[    nodes: Vec<Trie>]=],
    [=[}]=]
  } }),
  s("idiom.detect-if-32-bit-or-64-bit-architecture", { t {
    [=[match std::mem::size_of::<&char>() {]=],
    [=[    4 => f32(),]=],
    [=[    8 => f64(),]=],
    [=[    _ => {}]=],
    [=[}]=]
  } }),
  s("idiom.multiply-all-the-elements-of-a-list", { t {
    [=[let elements = elements.into_iter().map(|x| c * x).collect::<Vec<_>>();]=],
    [=[elements.iter_mut().for_each(|x| *x *= c);]=]
  } }),
  s("idiom.execute-procedures-depending-on-options", { t {
    [=[if let Some(arg) = ::std::env::args().nth(1) {]=],
    [=[    if &arg == "f" {]=],
    [=[        fox();]=],
    [=[    } else if &arg = "b" {]=],
    [=[        bat();]=],
    [=[    } else {]=],
    [=[	eprintln!("invalid argument: {}", arg),]=],
    [=[    }]=],
    [=[} else {]=],
    [=[    eprintln!("missing argument");]=],
    [=[}]=],
    [=[if let Some(arg) = ::std::env::args().nth(1) {]=],
    [=[    match arg.as_str() {]=],
    [=[        "f" => fox(),]=],
    [=[        "b" => box(),]=],
    [=[        _ => eprintln!("invalid argument: {}", arg),]=],
    [=[    };]=],
    [=[} else {]=],
    [=[    eprintln!("missing argument");]=],
    [=[}]=]
  } }),
  s("idiom.print-list-elements-by-group-of-2", { t {
    [=[for pair in list.chunks(2) {]=],
    [=[    println!("({}, {})", pair[0], pair[1]);]=],
    [=[}]=]
  } }),
  s("idiom.open-url-in-the-default-browser", { t {
    [=[use webbrowser;]=],
    [=[webbrowser::open(s).expect("failed to open URL");]=],
    [=[]=]
  } }),
  s("idiom.last-element-of-list", { t {
    [=[let x = items[items.len()-1];]=],
    [=[let x = items.last().unwrap();]=]
  } }),
  s("idiom.concatenate-two-lists", { t {
    [=[let ab = [a, b].concat();]=]
  } }),
  s("idiom.trim-prefix", { t {
    [=[let t = s.trim_start_matches(p);]=],
    [=[let t = if s.starts_with(p) { &s[p.len()..] } else { s };]=],
    [=[let t = s.strip_prefix(p).unwrap_or(s);]=]
  } }),
  s("idiom.trim-suffix", { t {
    [=[let t = s.trim_end_matches(w);]=],
    [=[let t = s.strip_suffix(w).unwrap_or(s);]=]
  } }),
  s("idiom.string-length", { t {
    [=[let n = s.chars().count();]=]
  } }),
  s("idiom.get-map-size", { t {
    [=[let n = mymap.len();]=]
  } }),
  s("idiom.add-an-element-at-the-end-of-a-list", { t {
    [=[s.push(x);]=]
  } }),
  s("idiom.insert-an-entry-in-a-map", { t {
    [=[use std::collection::HashMap;]=],
    [=[m.insert(k, v);]=]
  } }),
  s("idiom.format-a-number-with-grouped-thousands", { t {
    [=[use separator::Separatable;]=],
    [=[println!("{}", 1000.separated_string());]=]
  } }),
  s("idiom.make-http-post-request", { t {
    [=[[dependencies]]=],
    [=[error-chain = "0.12.4"]=],
    [=[reqwest = { version = "0.11.2", features = ["blocking"] }]=],
    [=[]=],
    [=[use error_chain::error_chain;]=],
    [=[use std::io::Read;]=],
    [=[let client = reqwest::blocking::Client::new();]=],
    [=[let mut response = client.post(u).body("abc").send()?;]=]
  } }),
  s("idiom.bytes-to-hex-string", { t {
    [=[use hex::ToHex;]=],
    [=[let s = a.encode_hex::<String>();]=],
    [=[use core::fmt::Write;]=],
    [=[let mut s = String::with_capacity(2 * n);]=],
    [=[for byte in a {]=],
    [=[    write!(s, "{:02X}", byte)?;]=],
    [=[}]=]
  } }),
  s("idiom.hex-string-to-byte-array", { t {
    [=[use hex::FromHex;]=],
    [=[let a: Vec<u8> = Vec::from_hex(s).expect("Invalid Hex String");]=]
  } }),
  s("idiom.check-if-point-is-inside-rectangle", { t {
    [=[struct Rect {]=],
    [=[    x1: i32,]=],
    [=[    x2: i32,]=],
    [=[    y1: i32,]=],
    [=[    y2: i32,]=],
    [=[}]=],
    [=[]=],
    [=[impl Rect {]=],
    [=[    fn contains(&self, x: i32, y: i32) -> bool {]=],
    [=[        return self.x1 < x && x < self.x2 && self.y1 < y && y < self.y2;]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.get-center-of-a-rectangle", { t {
    [=[struct Rectangle {]=],
    [=[    x1: f64,]=],
    [=[    y1: f64,]=],
    [=[    x2: f64,]=],
    [=[    y2: f64,]=],
    [=[}]=],
    [=[]=],
    [=[impl Rectangle {]=],
    [=[    pub fn center(&self) -> (f64, f64) {]=],
    [=[	    ((self.x1 + self.x2) / 2.0, (self.y1 + self.y2) / 2.0)]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.list-files-in-directory", { t {
    [=[let x = std::fs::read_dir(d).unwrap();]=],
    [=[let x = std::fs::read_dir(d)?.collect::<Result<Vec<_>, _>>()?;]=]
  } }),
  s("idiom.quine-program", { t {
    [=[fn main() {]=],
    [=[    let x = "fn main() {\n    let x = ";]=],
    [=[    let y = "print!(\"{}{:?};\n    let y = {:?};\n    {}\", x, x, y, y)\n}\n";]=],
    [=[    print!("{}{:?};]=],
    [=[    let y = {:?};]=],
    [=[    {}", x, x, y, y)]=],
    [=[}]=],
    [=[fn main(){print!("{},{0:?})}}","fn main(){print!(\"{},{0:?})}}\"")}]=],
    [=[fn main() {]=],
    [=[    print!("{}", include_str!("main.rs"))]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.tomorrow", { t {
    [=[let t = chrono::Utc::now().date().succ().to_string();]=]
  } }),
  s("idiom.execute-function-in-30-seconds", { t {
    [=[use std::time::Duration;]=],
    [=[use std::thread::sleep;]=],
    [=[sleep(Duration::new(30, 0));]=],
    [=[f(42);]=],
    [=[]=]
  } }),
  s("idiom.exit-program-cleanly", { t {
    [=[use std::process::exit;]=],
    [=[exit(0);]=]
  } }),
  s("idiom.filter-and-transform-list", { t {
    [=[let y = x.iter()]=],
    [=[	.filter(P)]=],
    [=[        .map(T)]=],
    [=[	.collect::<Vec<_>>();]=]
  } }),
  s("idiom.call-an-external-c-function", { t {
    [=[extern "C" {]=],
    [=[    /// # Safety]=],
    [=[    ///]=],
    [=[    /// `a` must point to an array of at least size 10]=],
    [=[    fn foo(a: *mut libc::c_double, n: libc::c_int);]=],
    [=[}]=],
    [=[]=],
    [=[let mut a = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];]=],
    [=[let n = 10;]=],
    [=[unsafe {]=],
    [=[    foo(a.as_mut_ptr(), n);]=],
    [=[}]=]
  } }),
  s("idiom.check-if-any-value-in-a-list-is-larger-than-a-limit", { t {
    [=[if a.iter().any(|&elem| elem > x) {]=],
    [=[    f()]=],
    [=[}]=]
  } }),
  s("idiom.declare-a-real-variable-with-at-least-20-digits", { t {
    [=[use rust_decimal::Decimal;]=],
    [=[use std::str::FromStr;]=],
    [=[let a = Decimal::from_str("1234567890.123456789012345").unwrap();]=]
  } }),
  s("idiom.pass-a-two-dimensional-array", { t {
    [=[#[macro_use] extern crate itertools;]=],
    [=[fn foo(a: Vec<Vec<usize>>) {]=],
    [=[    println!(]=],
    [=[        "Length of array: {}",]=],
    [=[        a.clone()]=],
    [=[            .into_iter()]=],
    [=[            .flatten()]=],
    [=[            .collect::<Vec<usize>>()]=],
    [=[            .len()]=],
    [=[    );]=],
    [=[]=],
    [=[    let mut sum = 0;]=],
    [=[    for (i, j) in izip!(&a[0], &a[1]) {]=],
    [=[        sum += i * j]=],
    [=[    }]=],
    [=[]=],
    [=[    println!("Sum of all products of indices: {}", sum);]=],
    [=[}]=]
  } }),
  s("idiom.pass-a-sub-array", { t {
    [=[fn foo(el: &mut i32) {]=],
    [=[    *el = 42;]=],
    [=[}]=],
    [=[a.iter_mut().take(m).step_by(2).for_each(foo);]=]
  } }),
  s("idiom.get-a-list-of-lines-from-a-file", { t {
    [=[use std::io::prelude::*;]=],
    [=[use std::io::BufReader;]=],
    [=[use std::fs::File;]=],
    [=[let lines = BufReader::new(File::open(path).unwrap())]=],
    [=[	.lines()]=],
    [=[	.collect::<Vec<_>>();]=]
  } }),
  s("idiom.abort-program-execution-with-error-condition", { t {
    [=[use std::process;]=],
    [=[process::exit(x);]=]
  } }),
  s("idiom.return-hypotenuse", { t {
    [=[fn hypot(x:f64, y:f64)-> f64 {]=],
    [=[    let num = x.powi(2) + y.powi(2);]=],
    [=[    num.powf(0.5)]=],
    [=[}]=]
  } }),
  s("idiom.sum-of-squares", { t {
    [=[let s = data.iter().map(|x| x.powi(2)).sum::<f32>();]=]
  } }),
  s("idiom.get-an-environment-variable", { t {
    [=[use std::env;]=],
    [=[let foo = match env::var("FOO") {]=],
    [=[    Ok(val) => val,]=],
    [=[    Err(_e) => "none".to_string(),]=],
    [=[};]=],
    [=[use std::env;]=],
    [=[let foo = env::var("FOO").unwrap_or("none".to_string());]=],
    [=[use std::env;]=],
    [=[let foo = match env::var("FOO") {]=],
    [=[    Ok(val) => val,]=],
    [=[    Err(_e) => "none".to_string(),]=],
    [=[};]=],
    [=[use std::env;]=],
    [=[if let Ok(tnt_root) = env::var("TNT_ROOT") {]=],
    [=[     //]=],
    [=[}]=]
  } }),
  s("idiom.switch-statement-with-strings", { t {
    [=[match str {]=],
    [=[    "foo" => foo(),]=],
    [=[    "bar" => bar(),]=],
    [=[    "baz" => baz(),]=],
    [=[    "barfl" => barfl(),]=],
    [=[    _ => {}]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.allocate-a-list-that-is-automatically-deallocated", { t {
    [=[let a = vec![0; n];]=]
  } }),
  s("idiom.formula-with-arrays", { t {
    [=[for i in 0..a.len() {]=],
    [=[    a[i] = e * (a[i] + b[i] * c[i] + d[i].cos());]=],
    [=[}]=]
  } }),
  s("idiom.type-with-automatic-deep-deallocation", { t {
    [=[struct T {]=],
    [=[	s: String,]=],
    [=[	n: Vec<usize>,]=],
    [=[}]=],
    [=[]=],
    [=[fn main() {]=],
    [=[	let v = T {]=],
    [=[		s: "Hello, world!".into(),]=],
    [=[		n: vec![1,4,9,16,25]]=],
    [=[	};]=],
    [=[}]=]
  } }),
  s("idiom.create-folder", { t {
    [=[use std::fs;]=],
    [=[fs::create_dir(path)?;]=],
    [=[use std::fs;]=],
    [=[fs::create_dir_all(path)?;]=]
  } }),
  s("idiom.check-if-folder-exists", { t {
    [=[use std::path::Path;]=],
    [=[let b: bool = Path::new(path).is_dir();]=]
  } }),
  s("idiom.case-insensitive-string-compare", { t {
    [=[use itertools::Itertools;]=],
    [=[for x in strings]=],
    [=[    .iter()]=],
    [=[    .combinations(2)]=],
    [=[    .filter(|x| x[0].to_lowercase() == x[1].to_lowercase())]=],
    [=[{]=],
    [=[    println!("{:?} == {:?}", x[0], x[1])]=],
    [=[}]=]
  } }),
  s("idiom.pad-string-on-the-left", { t {
    [=[use unicode_width::{UnicodeWidthChar, UnicodeWidthStr};]=],
    [=[if let Some(columns_short) = m.checked_sub(s.width()) {]=],
    [=[    let padding_width = c]=],
    [=[        .width()]=],
    [=[        .filter(|n| *n > 0)]=],
    [=[        .expect("padding character should be visible");]=],
    [=[    // Saturate the columns_short]=],
    [=[    let padding_needed = columns_short + padding_width - 1 / padding_width;]=],
    [=[    let mut t = String::with_capacity(s.len() + padding_needed);]=],
    [=[    t.extend((0..padding_needed).map(|_| c)]=],
    [=[    t.push_str(&s);]=],
    [=[    s = t;]=],
    [=[}]=]
  } }),
  s("idiom.create-a-zip-archive", { t {
    [=[use zip::write::FileOptions;]=],
    [=[let path = std::path::Path::new(_name);]=],
    [=[let file = std::fs::File::create(&path).unwrap();]=],
    [=[let mut zip = zip::ZipWriter::new(file); zip.start_file("readme.txt", FileOptions::default())?;                                                          ]=],
    [=[zip.write_all(b"Hello, World!\n")?;]=],
    [=[zip.finish()?;]=],
    [=[use zip::write::FileOptions;]=],
    [=[fn zip(_name: &str, _list: Vec<&str>) -> zip::result::ZipResult<()>]=],
    [=[{]=],
    [=[    let path = std::path::Path::new(_name);]=],
    [=[    let file = std::fs::File::create(&path).unwrap();]=],
    [=[    let mut zip = zip::ZipWriter::new(file);]=],
    [=[    for i in _list.iter() {]=],
    [=[        zip.start_file(i as &str, FileOptions::default())?;]=],
    [=[    }]=],
    [=[    zip.finish()?;]=],
    [=[    Ok(())]=],
    [=[}]=]
  } }),
  s("idiom.list-intersection", { t {
    [=[use std::collections::HashSet;]=],
    [=[let unique_a = a.iter().collect::<HashSet<_>>();]=],
    [=[let unique_b = b.iter().collect::<HashSet<_>>();]=],
    [=[]=],
    [=[let c = unique_a.intersection(&unique_b).collect::<Vec<_>>();]=],
    [=[use std::collections::HashSet;]=],
    [=[let set_a: HashSet<_> = a.into_iter().collect();]=],
    [=[let set_b: HashSet<_> = b.into_iter().collect();]=],
    [=[let c = set_a.intersection(&set_b);]=]
  } }),
  s("idiom.replace-multiple-spaces-with-single-space", { t {
    [=[use regex::Regex;]=],
    [=[let re = Regex::new(r"\s+").unwrap();]=],
    [=[let t = re.replace_all(s, " ");]=]
  } }),
  s("idiom.create-a-tuple-value", { t {
    [=[let t = (2.5, "hello", -1);]=]
  } }),
  s("idiom.remove-all-non-digits-characters", { t {
    [=[let t: String = s.chars().filter(|c| c.is_digit(10)).collect();]=]
  } }),
  s("idiom.find-the-first-index-of-an-element-in-list", { t {
    [=[let opt_i = items.iter().position(|y| *y == x);]=],
    [=[]=],
    [=[]=],
    [=[let i = match opt_i {]=],
    [=[   Some(index) => index as i32,]=],
    [=[   None => -1]=],
    [=[};]=],
    [=[let i = items.iter().position(|y| *y == x).map_or(-1, |n| n as i32);]=]
  } }),
  s("idiom.for-else-loop", { t {
    [=[let mut found = false;]=],
    [=[for item in items {]=],
    [=[    if item == &"baz" {]=],
    [=[        println!("found it");]=],
    [=[        found = true;]=],
    [=[        break;]=],
    [=[    }]=],
    [=[}]=],
    [=[if !found {]=],
    [=[    println!("never found it");]=],
    [=[}]=],
    [=[if let None = items.iter().find(|&&item| item == "rockstar programmer") {]=],
    [=[        println!("NotFound");]=],
    [=[    };]=],
    [=[items]=],
    [=[    .iter()]=],
    [=[    .find(|&&item| item == "rockstar programmer")]=],
    [=[    .or_else(|| {]=],
    [=[        println!("NotFound");]=],
    [=[        Some(&"rockstar programmer")]=],
    [=[    });]=]
  } }),
  s("idiom.add-element-to-the-beginning-of-the-list", { t {
    [=[use std::collections::VecDeque;]=],
    [=[items.push_front(x);]=]
  } }),
  s("idiom.declare-and-use-an-optional-argument", { t {
    [=[fn f(x: Option<()>) {]=],
    [=[    match x {]=],
    [=[        Some(x) => println!("Present {}", x),]=],
    [=[        None => println!("Not present"),]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.delete-last-element-from-list", { t {
    [=[items.pop();]=]
  } }),
  s("idiom.copy-a-list", { t {
    [=[let y = x.clone();]=]
  } }),
  s("idiom.copy-a-file", { t {
    [=[use std::fs;]=],
    [=[fs::copy(src, dst).unwrap();]=]
  } }),
  s("idiom.test-if-bytes-are-a-valid-utf-8-string", { t {
    [=[let b = std::str::from_utf8(&bytes).is_ok();]=]
  } }),
  s("idiom.read-a-command-line-boolean-flag", { t {
    [=[use clap::{Arg, App};]=],
    [=[let matches = App::new("My Program")]=],
    [=[                .arg(Arg::with_name("verbose")]=],
    [=[                    .short("v")]=],
    [=[                    .takes_value(false))]=],
    [=[                .get_matches();]=],
    [=[                   ]=],
    [=[if matches.is_present("verbose") {]=],
    [=[    println!("verbose is true")]=],
    [=[} else {]=],
    [=[    println!("verbose is false")]=],
    [=[}]=]
  } }),
  s("idiom.encode-bytes-to-base64", { t {
    [=[let s = base64::encode(data);]=]
  } }),
  s("idiom.decode-base64", { t {
    [=[let bytes = base64::decode(s).unwrap();]=],
    [=[]=]
  } }),
  s("idiom.xor-integers", { t {
    [=[let c = a ^ b;]=]
  } }),
  s("idiom.xor-byte-arrays", { t {
    [=[let c: Vec<_> = a.iter().zip(b).map(|(x, y)| x ^ y).collect();]=]
  } }),
  s("idiom.find-first-regular-expression-match", { t {
    [=[use regex::Regex;]=],
    [=[let re = Regex::new(r"\b\d\d\d\b").expect("failed to compile regex");]=],
    [=[let x = re.find(s).map(|x| x.as_str()).unwrap_or("");]=]
  } }),
  s("idiom.sort-2-lists-together", { t {
    [=[let mut tmp: Vec<_> = a.iter().zip(b).collect();]=],
    [=[tmp.as_mut_slice().sort_by_key(|(&x, _y)| x);]=],
    [=[let (aa, bb): (Vec<i32>, Vec<i32>) = tmp.into_iter().unzip();]=],
    [=[]=]
  } }),
  s("idiom.yield-priority-to-other-threads", { t {
    [=[::std::thread::yield_now();]=],
    [=[busywork();]=]
  } }),
  s("idiom.iterate-over-a-set", { t {
    [=[use std::collections::HashSet;]=],
    [=[for item in &x {]=],
    [=[    f(item);]=],
    [=[}]=]
  } }),
  s("idiom.print-list", { t {
    [=[println!("{:?}", a)]=]
  } }),
  s("idiom.print-a-map", { t {
    [=[println!("{:?}", m);]=]
  } }),
  s("idiom.print-value-of-custom-type", { t {
    [=[println!("{:?}", x);]=]
  } }),
  s("idiom.count-distinct-elements", { t {
    [=[use itertools::Itertools;]=],
    [=[let c = items.iter().unique().count();]=]
  } }),
  s("idiom.filter-list-in-place", { t {
    [=[let mut j = 0;]=],
    [=[for i in 0..x.len() {]=],
    [=[    if p(x[i]) {]=],
    [=[        x[j] = x[i];]=],
    [=[        j += 1;]=],
    [=[    }]=],
    [=[}]=],
    [=[x.truncate(j);]=],
    [=[x.retain(p);]=]
  } }),
  s("idiom.declare-and-assign-multiple-variables", { t {
    [=[let (a, b, c) = (42, "hello", 5.0);]=]
  } }),
  s("idiom.parse-binary-digits", { t {
    [=[let i = i32::from_str_radix(s, 2).expect("Not a binary number!");]=]
  } }),
  s("idiom.conditional-assignment", { t {
    [=[x = if condition() { "a" } else { "b" };]=]
  } }),
  s("idiom.print-stack-trace", { t {
    [=[use backtrace::Backtrace;]=],
    [=[let bt = Backtrace::new();]=],
    [=[println!("{:?}", bt);]=]
  } }),
  s("idiom.replace-value-in-list", { t {
    [=[for v in &mut x {]=],
    [=[    if *v == "foo" {]=],
    [=[        *v = "bar";]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.print-a-set", { t {
    [=[use std::collections::HashSet;]=],
    [=[println!("{:?}", x);]=]
  } }),
  s("idiom.count-backwards", { t {
    [=[(0..=5).rev().for_each(|i| println!("{}", i));]=],
    [=[]=]
  } }),
  s("idiom.traverse-list-backwards", { t {
    [=[for (i, item) in items.iter().enumerate().rev() {]=],
    [=[    println!("{} = {}", i, *item);]=],
    [=[}]=]
  } }),
  s("idiom.convert-list-of-strings-to-list-of-integers", { t {
    [=[let b: Vec<i64> = a.iter().map(|x| x.parse::<i64>().unwrap()).collect();]=],
    [=[let b: Vec<i32> = a.iter().flat_map(|s| s.parse().ok()).collect();]=],
    [=[]=]
  } }),
  s("idiom.split-on-several-separators", { t {
    [=[let parts: Vec<_> = s.split(&[',', '-', '_'][..]).collect();]=]
  } }),
  s("idiom.create-an-empty-list-of-strings", { t {
    [=[let items: Vec<String> = vec![];]=]
  } }),
  s("idiom.format-time-hours-minutes-seconds", { t {
    [=[use time::macros::format_description;]=],
    [=[let format = format_description!("[hour]:[minute]:[second]");]=],
    [=[let x = d.format(&format).expect("Failed to format the time");]=]
  } }),
  s("idiom.count-trailing-zero-bits", { t {
    [=[let t = n.trailing_zeros();]=]
  } }),
  s("idiom.integer-logarithm-in-base-2", { t {
    [=[fn log2d(n: f64) -> f64 {]=],
    [=[    n.log2().floor()]=],
    [=[}]=],
    [=[]=],
    [=[fn log2u(n: f64) -> f64 {]=],
    [=[    n.log2().ceil()]=],
    [=[}]=],
    [=[]=],
    [=[fn main() {]=],
    [=[    for n in 1..=12 {]=],
    [=[        let f = f64::from(n);]=],
    [=[        println!("{} {} {}", n, log2d(f), log2u(f));]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.automated-passing-of-array-bounds", { t {
    [=[fn foo(v: Vec<Vec<i32>>) {]=],
    [=[    println!("{} {}", v.len(), v[0].len());]=],
    [=[}]=],
    [=[]=],
    [=[let v = vec![]=],
    [=[    vec![1, 2, 3],]=],
    [=[    vec![4, 5, 6],]=],
    [=[];]=],
    [=[foo(v);]=],
    [=[fn foo<const X: usize, const Y: usize>(_: [[i32;X];Y]) {]=],
    [=[    println!("{} {}", Y, X);]=],
    [=[}]=],
    [=[]=],
    [=[let a = []=],
    [=[    [1, 2, 3],]=],
    [=[    [4, 5, 6],]=],
    [=[];]=],
    [=[foo(a);]=]
  } }),
  s("idiom.even-parity-bit", { t {
    [=[let i = 42i32;]=],
    [=[let p = i.count_ones() % 2;]=]
  } }),
  s("idiom.repeated-string", { t {
    [=[let s = v.repeat(n);]=]
  } }),
  s("idiom.pass-string-to-argument-that-can-be-of-any-type", { t {
    [=[use std::any::Any;]=],
    [=[fn foo(x: &dyn Any) {]=],
    [=[    if let Some(s) = x.downcast_ref::<String>() {]=],
    [=[        println!("{}", s);]=],
    [=[    } else {]=],
    [=[        println!("Nothing")]=],
    [=[    }]=],
    [=[}]=],
    [=[]=],
    [=[fn main() {]=],
    [=[    foo(&"Hello, world!".to_owned());]=],
    [=[    foo(&42);]=],
    [=[}]=]
  } }),
  s("idiom.user-defined-operator", { t {
    [=[use std::ops::Mul;]=],
    [=[struct Vector {]=],
    [=[    x: f32,]=],
    [=[    y: f32,]=],
    [=[    z: f32,]=],
    [=[}]=],
    [=[]=],
    [=[impl Mul for Vector {]=],
    [=[    type Output = Self;]=],
    [=[]=],
    [=[    fn mul(self, rhs: Self) -> Self {]=],
    [=[        Self {]=],
    [=[            x: self.y * rhs.z - self.z * rhs.y,]=],
    [=[            y: self.z * rhs.x - self.x * rhs.z,]=],
    [=[            z: self.x * rhs.y - self.y * rhs.x,]=],
    [=[        }]=],
    [=[    }]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.enum-to-string", { t {
    [=[let e = t::bike;]=],
    [=[let s = format!("{:?}", e);]=],
    [=[]=],
    [=[println!("{}", s);]=]
  } }),
  s("idiom.play-fizzbuzz", { t {
    [=[for i in 1..101 {]=],
    [=[    match i {]=],
    [=[        i if (i % 15) == 0 => println!("FizzBuzz"),]=],
    [=[        i if (i % 3) == 0 => println!("Fizz"),]=],
    [=[        i if (i % 5) == 0 => println!("Buzz"),]=],
    [=[        _ => println!("{i}"),]=],
    [=[    }]=],
    [=[}]=],
    [=[]=]
  } }),
  s("idiom.check-if-folder-is-empty", { t {
    [=[use std::fs;]=],
    [=[let b = fs::read_dir(p).unwrap().count() == 0;]=]
  } }),
  s("idiom.remove-all-white-space-characters", { t {
    [=[let t: String = s.chars().filter(|c| !c.is_whitespace()).collect();]=]
  } }),
  s("idiom.insert-an-element-in-a-set", { t {
    [=[use std::collections::HashSet]=],
    [=[x.insert(e);]=]
  } }),
  s("idiom.remove-an-element-from-a-set", { t {
    [=[use std::collections::HashSet]=],
    [=[x.remove(e);]=],
    [=[use std::collections::HashSet;]=],
    [=[x.take(e)]=]
  } }),
  s("idiom.read-one-line-from-the-standard-input", { t {
    [=[let mut buffer = String::new();]=],
    [=[let mut stdin = io::stdin();]=],
    [=[stdin.read_line(&mut buffer).unwrap();]=]
  } }),
  s("idiom.read-list-of-strings-from-the-standard-input", { t {
    [=[use std::io::prelude::*;]=],
    [=[let lines = std::io::stdin().lock().lines().map(|x| x.unwrap()).collect::<Vec<String>>();]=]
  } }),
  s("idiom.filter-map", { t {
    [=[m.retain(|_, &mut v| p(v));]=]
  } }),
  s("idiom.use-a-point-as-a-map-key", { t {
    [=[use std::collections::HashMap;]=],
    [=[let mut map: HashMap<Point, String> = HashMap::new();]=],
    [=[map.insert(Point { x: 42, y: 5 }, "Hello".into());]=],
    [=[]=]
  } }),
  s("idiom.split-with-a-custom-string-separator", { t {
    [=[let parts = s.split(sep);]=],
    [=[let parts = s.split(sep).collect::<Vec<&str>>();]=],
    [=[let parts: Vec<&str> = s.split(sep).collect();]=]
  } }),
  s("idiom.create-a-zeroed-list-of-integers", { t {
    [=[let a = vec![0; n];]=]
  } }),
  s("idiom.set-variable-to-nan", { t {
    [=[let a: f64 = f64::NAN;]=]
  } }),
  s("idiom.iterate-over-characters-of-a-string", { t {
    [=[for (i, c) in s.chars().enumerate() {]=],
    [=[    println!("Char {} is {}", i, c);]=],
    [=[}]=]
  } }),
  s("idiom.number-of-bytes-of-a-string", { t {
    [=[let n = s.len();]=]
  } }),
  s("idiom.check-if-set-contains-a-value", { t {
    [=[let b = x.contains(&e);]=]
  } }),
  s("idiom.concatenate-two-strings", { t {
    [=[let s = format!("{}{}", a, b);]=],
    [=[let s = a + b;]=]
  } }),
  s("idiom.sort-sublist", { t {
    [=[items[i..j].sort_by(c);]=]
  } }),
  s("idiom.remove-sublist", { t {
    [=[items.drain(i..j)]=]
  } }),
  s("idiom.write-ni-hao-in-chinese-to-standard-output-in-utf-8", { t {
    [=[println!("Hello World and 你好")]=]
  } }),
  s("idiom.create-a-stack", { t {
    [=[let mut s: Vec<T> = vec![];]=],
    [=[s.push(x);]=],
    [=[let y = s.pop().unwrap();]=]
  } }),
  s("idiom.print-a-comma-separated-list-of-integers", { t {
    [=[let a = [1, 12, 42];]=],
    [=[println!("{}", a.map(|i| i.to_string()).join(", "))]=]
  } }),
  s("idiom.comment-out-a-single-line", { t {
    [=[// This is a comment]=]
  } }),
  s("idiom.recursive-fibonacci-sequence", { t {
    [=[fn fib(n: i32) -> i32{]=],
    [=[    if n < 2 {]=],
    [=[        1]=],
    [=[    }else{]=],
    [=[        fib(n - 2) + fib(n - 1)]=],
    [=[    }]=],
    [=[}]=]
  } }),
  s("idiom.string-interpolation", { t {
    [=[let s = format!("Our sun has {} planets", x);]=],
    [=[let s = format!("Our sun has {x} planets");]=]
  } }),
  s("idiom.encode-string-into-utf-8-bytes", { t {
    [=[let data = s.into_bytes();]=]
  } }),
  s("idiom.ensure-list-capacity", { t {
    [=[x.reserve(200);]=]
  } }),
  s("idiom.xor-encrypt-decrypt-string", { t {
    [=[fn xor(s: Vec<u8>, key: &[u8]) -> Vec<u8> {]=],
    [=[    let mut b = key.iter().cycle();]=],
    [=[    s.into_iter().map(|x| x ^ b.next().unwrap()).collect()]=],
    [=[}]=]
  } }),
}
