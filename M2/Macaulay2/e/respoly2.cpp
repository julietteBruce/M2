// Copyright 1996 Michael E. Stillman

#include "respoly2.hpp"
#include "text_io.hpp"
#include "polyring.hpp"
#include "freemod.hpp"
#include "geovec.hpp"

res2_poly::res2_poly(PolynomialRing *RR)
: R(RR), M(R->Nmonoms()), K(R->Ncoeffs())
{
  respoly_size = sizeof(res2term *) + sizeof(res2_pair *)
    + sizeof(ring_elem)
    + sizeof(int) * M->monomial_size();
}

res2_poly::~res2_poly()
{
}

int res2_poly::compare(const res2term *a, const res2term *b) const
{
  int cmp = M->compare(a->monom, b->monom);
  if (cmp != 0) return cmp;
  cmp = a->comp->compare_num - b->comp->compare_num;
  if (cmp > 0) return 1;
  if (cmp < 0) return -1;
  return 0;
}

res2term *res2_poly::new_term() const
{
  res2term *result = GETMEM(res2term*, respoly_size);
  result->next = NULL;
  return result;
}
res2term *res2_poly::new_term(ring_elem c, const int *m, res2_pair *x) const
    // Note: this does NOT copy 'c'
{
  res2term *result = new_term();
  result->coeff = c;
  M->copy(m, result->monom);
  result->comp = x;
  return result;
}

res2term *res2_poly::mult_by_monomial(const res2term *f, const int *m) const
{
  res2term head;
  res2term *result = &head;
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    {
      result->next = new_term();
      result = result->next;
      result->comp = tm->comp;
      result->coeff = K->copy(tm->coeff);
      M->mult(tm->monom, m, result->monom);
    }
  result->next = NULL;
  return head.next;
}

res2term *res2_poly::mult_by_coefficient(const res2term *f, const ring_elem c) const
{
  res2term head;
  res2term *result = &head;
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    {
      result->next = new_term();
      result = result->next;
      result->comp = tm->comp;
      result->coeff = K->mult(c,tm->coeff);
      M->copy(tm->monom, result->monom);
    }
  result->next = NULL;
  return head.next;
}

res2term *res2_poly::copy(const res2term *f) const
{
  res2term head;
  res2term *result = &head;
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    {
      result->next = new_term();
      result = result->next;
      result->comp = tm->comp;
      result->coeff = K->copy(tm->coeff);
      M->copy(tm->monom, result->monom);
    }
  result->next = NULL;
  return head.next;
}
void res2_poly::remove(res2term *&f) const
{
  while (f != NULL)
    {
      res2term *tmp = f;
      f = f->next;
      K->remove(tmp->coeff);
      deleteitem(tmp);
    }
}

res2term *res2_poly::mult_by_term(const res2term *f, ring_elem c, const int *m) const
{
  res2term head;
  res2term *result = &head;
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    {
      result->next = new_term();
      result = result->next;
      result->comp = tm->comp;
      result->coeff = K->mult(c, tm->coeff);
      M->mult(tm->monom, m, result->monom);
    }
  result->next = NULL;
  return head.next;
}
res2term *res2_poly::ring_mult_by_term(const ring_elem f, 
				     ring_elem c, const int *m, res2_pair *x) const
{
  res2term head;
  res2term *result = &head;
  for (const Nterm *tm = f; tm != NULL; tm = tm->next)
    {
      result->next = new_term();
      result = result->next;
      result->comp = x;
      result->coeff = K->mult(c, tm->coeff);
      M->mult(tm->monom, m, result->monom);
    }
  result->next = NULL;
  return head.next;
}

void res2_poly::make_monic(res2term *&f) const
{
  if (f == NULL) return;
  ring_elem c_inv = K->invert(f->coeff);

  for (res2term *tm = f; tm != NULL; tm = tm->next)
    K->mult_to(tm->coeff, c_inv);

  K->remove(c_inv);
}


void res2_poly::add_to(res2term * &f, res2term * &g) const
{
  if (g == NULL) return;
  if (f == NULL) { f = g; g = NULL; return; }
  res2term head;
  res2term *result = &head;
  while (1)
    switch (compare(f, g))
      {
      case -1:
	result->next = g;
	result = result->next;
	g = g->next;
	if (g == NULL) 
	  {
	    result->next = f; 
	    f = head.next;
	    return;
	  }
	break;
      case 1:
	result->next = f;
	result = result->next;
	f = f->next;
	if (f == NULL) 
	  {
	    result->next = g; 
	    f = head.next;
	    g = NULL;
	    return;
	  }
	break;
      case 0:
	res2term *tmf = f;
	res2term *tmg = g;
	f = f->next;
	g = g->next;
	K->add_to(tmf->coeff, tmg->coeff);
	if (K->is_zero(tmf->coeff))
	  deleteitem(tmf);
	else
	  {
	    result->next = tmf;
	    result = result->next;
	  }
	deleteitem(tmg);
	if (g == NULL) 
	  {
	    result->next = f; 
	    f = head.next;
	    return;
	  }
	if (f == NULL) 
	  {
	    result->next = g; 
	    f = head.next;
	    g = NULL;
	    return;
	  }
	break;
      }
}

void res2_poly::subtract_multiple_to(res2term *& f, ring_elem c, 
				    const int *m, const res2term *g) const
    // f := f - c * m * g
{
  ring_elem minus_c = K->negate(c);
  res2term *h = mult_by_term(g, minus_c, m);
  add_to(f, h);
  K->remove(minus_c);
}
void res2_poly::ring_subtract_multiple_to(res2term *& f, ring_elem c, 
					 const int *m, res2_pair *x, const ring_elem g) const
    // f := f - c * m * g * x, where g is a ring element
{
  ring_elem minus_c = K->negate(c);
  res2term *h = ring_mult_by_term(g, minus_c, m, x);
  add_to(f, h);
  K->remove(minus_c);
}

int res2_poly::n_terms(const res2term *f) const
{
  int result = 0;
  for ( ; f != NULL; f = f->next)
    result++;
  return result;
}

void res2_poly::elem_text_out(const res2term *f) const
{
  buffer o;
  elem_text_out(o, f);
  emit(o.str());
}
void res2_poly::elem_text_out(buffer &o, const res2term *f) const
{
  if (f == NULL)
    {
      o << "0";
      return;
    }

  int old_one = p_one;
  int old_parens = p_parens;
  int old_plus = p_plus;

  p_one = 0;
  p_parens = 1;
  p_plus = 0;
  for (const res2term *t = f; t != NULL; t = t->next)
    {
      int isone = M->is_one(t->monom);
      K->elem_text_out(o,t->coeff);
      if (!isone)
	M->elem_text_out(o, t->monom);
      o << "<" << t->comp->me << ">";
      p_plus = 1;
    }

  p_one = old_one;
  p_parens = old_parens;
  p_plus = old_plus;
}

vec res2_poly::to_vector(const res2term *f, const FreeModule *F, 
			    int /*to_minimal*/) const
{
  vecHeap H(F);
  int *mon = M->make_one();
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    {
//    int x = (to_minimal ? tm->comp->minimal_me : tm->comp->me);
      int x = tm->comp->me; // MES: Currently used for non-minimal as well...
      M->divide(tm->monom, tm->comp->syz->monom, mon);

      ring_elem a = R->make_flat_term(tm->coeff, mon);
      vec tmp = R->make_vec(x,a);
      H.add(tmp);
    }
  M->remove(mon);
  return H.value();
}

res2term *res2_poly::from_vector(const array<res2_pair *> &base, const vec v) const
{
  res2term head;
  res2term *result = &head;

  for (vecterm *w = v; w != NULL; w = w->next)
    for (Nterm *t = w->coeff; t != 0; t = t->next)
      {
	result->next = new_term();
	result = result->next;
	result->comp = base[w->comp];
	result->coeff = t->coeff;
	M->copy(t->monom, result->monom);
	M->mult(result->monom, result->comp->syz->monom, result->monom);
    }
  result->next = NULL;
  // Now we must sort these
  sort(head.next);
  return head.next;
}

res2term *res2_poly::strip(const res2term *f) const
{
  res2term head;
  res2term *result = &head;
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    if (tm->comp->syz_type != SYZ2_NOT_MINIMAL)
      {
	result->next = new_term();
	result = result->next;
	result->comp = tm->comp;
	result->coeff = K->copy(tm->coeff);
	M->copy(tm->monom, result->monom);
      }
  result->next = NULL;
  return head.next;
}

const res2term *res2_poly::component_occurs_in(const res2_pair *x, 
					  const res2term *f) const
{
  for (const res2term *tm = f; tm != NULL; tm = tm->next)
    if (tm->comp == x) return tm;
  return NULL;
}

void res2_poly::sort(res2term *&f) const
{
  // Divide f into two lists of equal length, sort each,
  // then add them together.  This allows the same monomial
  // to appear more than once in 'f'.
  
  if (f == NULL || f->next == NULL) return;
  res2term *f1 = NULL;
  res2term *f2 = NULL;
  while (f != NULL)
    {
      res2term *t = f;
      f = f->next;
      t->next = f1;
      f1 = t;

      if (f == NULL) break;
      t = f;
      f = f->next;
      t->next = f2;
      f2 = t;
    }
  
  sort(f1);
  sort(f2);
  add_to(f1, f2);
  f = f1;
}

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e "
// End:
