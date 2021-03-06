subroutine EigValSym(ain, n, eval, ul)
!-------------------------------------------------------------------------------
!
!   This subroutine will return the eigenvalues of the symmetric square 
!   matrix Ain, ordered from greatest to least.
!
!   Calling Parameters
!
!       IN
!           Ain     Input symmetric matrix. By default, only the
!                   upper portion is used.
!           n       Order of the matrix Ain.
!
!       OUT
!           eval    Vector of length n of the eigenvalues of Ain.
!
!       OPTIONAL
!           uplo    Use the upper 'U' or lower 'L' portion of the 
!                   input symmetric matrix.
!
!   The eigenvalues and eigenvectors are determined by reducing the
!   matrix to
!
!       A = Z L Z = Q (S L S') Q' 
!
!   by the two operations:
!
!   (1) The real symmetric square matrix is reduced to tridiagonal form
!       A = Q T Q'
!   where Q is orthogonal, and T is symmetric tridiagonal.
!   (2) The tridiagonal matrix is reduced to 
!       T = S L S'
!
!   The eigenvalues of A correspond to L (which is a diagonal).
!
!   Copyright (c) 2005-2019, SHTOOLS
!   All rights reserved.
!
!-------------------------------------------------------------------------------
    use ftypes

    implicit none

    real(dp), intent(in) :: ain(:,:)
    integer, intent(in) :: n
    real(dp), intent(out) :: eval(:)
    character, intent(in), optional :: ul
    integer, parameter :: nb = 80, nbl = 10
    character :: uplo
    real(dp) :: d(n), e(n), tau(n-1), work(nb*n), vl, vu, abstol, w(n)
    real(dp), allocatable :: a(:,:), z(:,:)
    integer :: lwork, info, il, iu, m, isuppz(2*n), liwork, iwork(nbl*n), &
               i, astat(2)
#ifdef LAPACK_UNDERSCORE
#define dsytrd dsytrd_
#define dstegr dstegr_
#endif
    external  dsytrd, dstegr

    if (size(ain(:,1)) < n .or. size(ain(1,:)) < n) then
        print*, "Error --- EigValSym"
        print*, "AIN must be dimensioned as (N, N) where N is ", n
        print*, "Input array is dimensioned as ", size(ain(:,1)), size(ain(1,:))
        stop

    else if (size(eval) < n) then
        print*, "Error --- EigValSym"
        print*, "EVAL must be dimensioned as (N) where N is ", n
        print*, "Input array is dimensioned as ", size(eval)
        stop

    end if

    allocate (a(n,n), stat = astat(1))
    allocate (z(n,n), stat = astat(2))

    if (astat(1) /= 0 .or. astat(2) /= 0) then
        print*, "Error --- EigValSym"
        print*, "Problem allocating arrays A and Z", astat(1), astat(2)
        stop
    end if

    lwork = nb*n
    liwork = nbl*n

    eval = 0.0_dp
    a(1:n,1:n) = ain(1:n,1:n)

    if (present(ul)) then
        uplo = ul
    else
        uplo = "U"
    end if

    !---------------------------------------------------------------------------
    !
    !   Factor A = Q T Q'
    !
    !---------------------------------------------------------------------------

    call dsytrd(uplo, n, a, n, d, e(1:n-1), tau, work, lwork, info)

    if (info /= 0) then
        print*, "Error --- EigValSym"
        print*, "Problem tri-diagonalizing input matrix"
        stop
        
    else
        if ( work(1) > dble(lwork) ) then
            print*, "Warning --- EigValSym"
            print*, "Consider changing value of nb to ", work(1)/n, &
                    " and recompile the SHTOOLS archive."
        end if

    end if

    !---------------------------------------------------------------------------
    !
    !   Factor T = S L S'
    !
    !---------------------------------------------------------------------------

    abstol = 0.0_dp

    call dstegr('n','a', n, d, e, vl, vu, il, iu, abstol, m,  w, &
                z, n, isuppz, work, lwork, iwork, liwork, info)

    if (info /= 0) then
        print*, "Error --- EigValSym"
        print*, "Problem determining eigenvalues and eigenvectors of " // &
                "tridiagonal matrix."
        if (info == 1) print*, "Internal error  in  DLARRE"
        if (info == 2) print*, "Internal error in DLARRV"
        stop

    else
        if (work(1) > dble(lwork) ) then
            print*, "Warning --- EigValSym"
            print*, "Consider changing value of nb to ", work(1)/n, &
                    " and recompile the SHTOOLS archive."
        end if

        if (iwork(1) > liwork ) then
            print*, "Warning --- Eigsym"
            print*, "Consider changing value of nb to ", iwork(1)/n, &
                    " and recompile the SHTOOLS archive."
        end if
        
    end if

    ! Reorder eigenvalues from greatest to least.

    do i = 1, n
        eval(i) = w(n+1-i)
    end do

    deallocate(a)
    deallocate(z)

end subroutine EigValSym
