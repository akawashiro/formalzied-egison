Set Warnings "-notation-overridden,-parsing".
From Coq Require Import Strings.String.
From Coq Require Import Strings.Ascii.
From Coq Require Import Lists.List.
From Coq Require Import Program.Basics.
From Egison Require Import Maps.

Module Egison.

  Definition varid := string.

   Inductive tm : Type :=
  | tvar : varid -> tm
  | tint : nat -> tm
  (* | tlmb : varid -> tm -> tm *)
  (* | tapp : tm -> tm -> tm *)
  | ttpl : list tm -> tm
  | tcll : list tm -> tm
  | tpair : tm -> tm -> tm
  | tmal : tm -> tm -> (list (ptn * tm)) -> tm
  | tsm : tm
  | tmtc : (list (pptn * tm * (list (dptn * tm)))) -> tm
  | ttplmtc : list tm -> tm
  with ptn : Type :=
  | pwld : ptn
  | pvar : varid -> ptn
  | pval : tm -> ptn
  | ppair : ptn -> ptn -> ptn
 with pptn : Type :=
  | ppdol : pptn
  | ppvar : varid -> pptn
  | pppair : pptn -> pptn -> pptn
  with dptn : Type :=
  | dpvar :  varid -> dptn
  | dppair :  dptn -> dptn -> dptn.

  Open Scope string_scope.
  Definition x :=  "x".
  Definition y := "y".
  Definition z := "z".
  Close Scope string_scope.

  Definition ppex1 := ppdol : pptn.

  Definition env := partial_map tm.

  (* Definition mlcssize (f : tm -> nat) (mcl : pptn * tm * (list (dptn * tm))) : nat := *)
  (*   let '(_, m1, l) := mcl in *)
  (*   max (f m1) (fold_left max (map (compose f snd) l) 0). *)

  (* Fixpoint tmsize (m: tm) : nat := *)
  (*   match m with *)
  (*   | tvar _ => 1 *)
  (*   | tint _ => 1 *)
  (*   (* | tlmb _ n => 1 + tmsize n *) *)
  (*   (* | tapp n1 n2 => 1 + max (tmsize n1) (tmsize n2) *) *)
  (*   | ttpl ms => 1 + fold_left max (map tmsize ms) 0 *)
  (*   | tcll ms => 1 + fold_left max (map tmsize ms) 0 *)
  (*   | tpair m1 m2 => 1 + max (tmsize m1) (tmsize m2) *)
  (*   | tmal m1 m2 pts => 1 + max (max (tmsize m1) (tmsize m2)) (fold_left max (map (compose tmsize snd) pts) 0) *)
  (*   | tsm => 1 *)
  (*   | tmtc mcl => 1 + fold_left max (map (mlcssize tmsize) mcl) 0 *)
  (*   end. *)

  Definition mclsvalue (f : tm -> Prop) (mcl : pptn * tm * (list (dptn * tm))) :=
    let '(_, m1, l) := mcl in (f m1) /\ (List.Forall (fun m => f (snd m))) l.

  Definition mclstms (mcl : pptn * tm * (list (dptn * tm))) : list tm :=
    let '(_, m1, l) := mcl in
    m1 :: map (fun m => snd m) l.

  Inductive value : tm -> Prop :=
  | vvar : forall i, value (tvar i)
  | vint : forall i, value (tint i)
  (* | vlmb : forall i m, value (tlmb i m) *)
  | vtpl : forall ms, Forall value ms -> value (ttpl ms)
  | vcll : forall ms, Forall value ms -> value (tcll ms)
  | vpair : forall m1 m2, value m1 /\ value m2 -> value (tpair m1 m2)
  | vmal : forall m1 m2 pts, value m1 -> value m2 -> Forall (fun t => value (snd t)) pts -> value (tmal m1 m2 pts)
  | vmtc : forall mcls, Forall value (concat (map mclstms mcls)) -> value (tmtc mcls)
  | vtplmtc : forall ms, Forall value ms -> value (ttplmtc ms).

  Import ListNotations.

  Definition ms : Type := ((list (ptn * tm * env * tm)) * env * env).
  Definition ma : Type := (ptn * tm * env * tm).

  Fixpoint filtersome {A: Type} (l: list (option A)) : list A :=
    match l with
    | [] => []
    | (Some v)::r => v::filtersome r
    | None::r => filtersome r
    end.

  Fixpoint zip {A B: Type} (l1:list A)  (l2: list B) : (list (A*B)) :=
    match (l1, l2) with
    | ([], _) => []
    | (_, []) => []
    | (h1::r1, h2::r2) => (h1,h2) :: zip r1 r2
    end.

  Fixpoint zip4 {A B C D: Type} (l1:list A)  (l2: list B) (l3: list C) (l4: list D) : (list (A*B*C*D)) :=
    match (l1, l2, l3, l4) with
    | ([], _, _, _) => []
    | (_, [], _, _) => []
    | (_, _, [], _) => []
    | (_, _, _, []) => []
    | (h1::r1, h2::r2, h3::r3, h4::r4) => (h1,h2,h3,h4) :: zip4 r1 r2 r3 r4
    end.

  Definition is_tpair (t: tm) : Prop :=
    match t with
    | (tpair _ _) => True
    | _ => False
    end.

  Definition is_pval (p: ptn) : Prop :=
    match p with
    | (pval _) => True
    | _ => False
    end.

  Definition is_ppair (p: ptn) : Prop :=
    match p with
    | (ppair _ _) => True
    | _ => False
    end.

  Inductive eval : env -> (tm * tm)-> Prop :=
  | evar : forall i e, eval e ((tvar i), (tvar i))
  | eint : forall i e, eval e ((tint i), (tint i))
  | etpl : forall e ts vs, Forall (eval e) (zip ts vs) -> eval e ((ttpl ts), (ttpl vs))
  | ecll : forall e ts vs, Forall (eval e) (zip ts vs) -> eval e ((tcll ts), (tcll vs))
  | epair : forall e t1 t2 v1 v2, eval e (t1, v1) -> eval e (t2, v2) -> eval e ((tpair t1 t2), (tpair v1 v2))
  | esm : forall Gamma, eval Gamma (tsm, tsm)
  (* | emtc : forall Gamma (ts: (list (pptn * tm * (list (dptn * tm))))), eval Gamma ((tmtc ts), (tmtc vs)) *)
  | etplmtc : forall Gamma ts vs, Forall (eval Gamma) (zip ts vs) -> eval Gamma ((ttplmtc ts), (ttplmtc vs))

  with evalmtc : env -> tm -> list (tm * env) -> Prop :=
  | emtcsm : forall Gamma, evalmtc Gamma tsm [(tsm, Gamma)]
  | emtcmtc : forall Gamma l, evalmtc Gamma (tmtc l) [((tmtc l), Gamma)]
  | emtctpl : forall Gamma ms ms1, eval Gamma ((ttplmtc ms), (ttplmtc ms1)) -> evalmtc Gamma (ttplmtc ms1) (map (fun m => (m,Gamma)) ms1)

  with evaldp : dptn -> tm -> option env -> Prop :=
  | edpvar : forall z v, value v -> evaldp (dpvar z) v (Some (z |-> v))
  | edppair : forall p1 p2 v1 v2 g1 g2,
      value v1 -> value v2 -> evaldp p1 v1 (Some g1) -> evaldp p2 v2 (Some g2) ->
      evaldp (dppair p1 p2) (tpair v1 v2) (Some (g1 @@ g2))
  | edpfail : forall t p1 p2, not (is_tpair t) -> evaldp (dppair p1 p2) t None

  with evalpp : pptn -> env -> ptn -> option ((list ptn) * env) -> Prop :=
  | eppdol : forall g p, evalpp ppdol g p (Some ([p], empty))
  | eppvar : forall i g m v, eval g (m, v) -> evalpp (ppvar i) g (pval m) (Some ([], (y |-> v)))
  | epppair : forall pp1 pp2 p1 p2 g pv1 pv2 g1 g2,
                evalpp pp1 g p1 (Some (pv1,g1)) -> evalpp pp2 g p2 (Some (pv2,g2)) ->
                evalpp (pppair pp2 pp2) g (ppair p1 p2) (Some ((pv1 ++ pv2), (g1 @@ g2)))
  | eppvarfail : forall y g p, not (is_pval p) -> evalpp (ppvar y) g p None
  | epppairfail : forall pp1 pp2 p g, not (is_ppair p) -> evalpp (pppair pp1 pp2) g p None

  with evalms1 : ((list ms) * option env * option (list ms) * option (list ms)) -> Prop :=
  | ems1nil : evalms1 ([], None, None, None)
  | ems1anil : forall sv g d, evalms1 ((([],g,d)::sv), (Some d), None, (Some sv))
  | ems1 : forall p m mg v av g d sv avv d1,
        evalma (g @@ d) (p,m,mg,v) avv d1 ->
        evalms1 ((((p,m,mg,v)::av, g, d)::sv), None, (Some (map (fun ai => (ai ++ av, g, d @@ d1)) avv)), (Some sv))

  with evalms2 : (list (list ms)) -> (list env) -> (list (list ms)) -> Prop :=
  | ems2 : forall svv gvv svv1 svv2,
      Forall evalms1 (zip4 svv gvv svv1 svv2) ->
      evalms2 svv (filtersome gvv) ((filtersome svv1) ++ (filtersome svv2))

  with evalms3 : (list (list ms)) -> (list env) -> Prop :=
  | ems3nil : evalms3 [] []
  | ems3 : forall svv gv svv1 dv, evalms2 svv gv svv1 -> evalms3 svv dv ->
                             evalms3 svv (gv ++ dv)

  with evalma : env -> ma -> list (list ma) -> env -> Prop :=
  | emasome : forall x g v d, evalma g (pvar x, tsm, d, v) [[]] (x |-> v)
  | emappfail : forall p g pp m sv pv d v avv g1,
      evalpp pp g p None -> evalma g (p,(tmtc pv),d,v) avv g1 ->
      evalma g (p,tmtc ((pp,m,sv)::pv),d,v) avv g1
  | emadpfail : forall p g pp m dp n sv pv d v pv1 d1 avv g1,
      evalpp pp g p (Some (pv1, d1)) -> evaldp dp v None ->
      evalma g (p, tmtc ((pp,m,sv)::pv),d,v) avv g1 ->
      evalma g (p, tmtc ((pp,m,(dp,n)::sv)::pv),d,v) avv g1.
  | ema : forall p Gamma pp M dp N sigma_v Delta v pv' Delta' Delta'' vvv' mv',
      evalpp pp Gamma p Some (pv', Delta') ->
      evaldp dp v (Some Delta'') ->

End Egison.
