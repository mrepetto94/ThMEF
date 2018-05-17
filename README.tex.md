# ThMEF
A git repository for the master thesis I wrote on Multi-criteria Analysis. The thesis was about building two transportation models:
* A model for profit allocation in multinationals;
* A model on Green Supply Chain management;

Both the models were created using the Goal Programming approach.

## In brief
Starting from the concept of Multi-criteria optimization, which is defined as:
$$
Min[f_1(x),f_2(x),...,f_k(x)] \quad i=1,...,k \quad where \quad k\geq2
$$
Then the general Goal Promming formulation is given, which takes the following optimization form:
$$
\begin{equation*}
\begin{aligned}
& \underset{n,p}{\text{minimize}}
& & a=h(n,p) \\
& \text{subject to}
& & f_q(x)+n_q-p_q=b_q \\
& & & x\in F \\
& & & n_q,p_q\geq 0 
\end{aligned}
\end{equation*}
$$

The advantage of GP is that can be solved through LP solvers and in its weighted flavor allow for the direct tradeoff between objectives.

## Author
* **Marco Repetto**: [LinkedIn](https://www.linkedin.com/in/marco-repetto-256562b3/)
