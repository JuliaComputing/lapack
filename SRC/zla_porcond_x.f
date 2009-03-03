      DOUBLE PRECISION FUNCTION ZLA_PORCOND_X( UPLO, N, A, LDA, AF, 
     $                             LDAF, X, INFO, WORK, RWORK )
*
*     -- LAPACK routine (version 3.2)                                 --
*     -- Contributed by James Demmel, Deaglan Halligan, Yozo Hida and --
*     -- Jason Riedy of Univ. of California Berkeley.                 --
*     -- November 2008                                                --
*
*     -- LAPACK is a software package provided by Univ. of Tennessee, --
*     -- Univ. of California Berkeley and NAG Ltd.                    --
*
      IMPLICIT NONE
*     ..
*     .. Scalar Arguments ..
      CHARACTER          UPLO
      INTEGER            N, LDA, LDAF, INFO
*     ..
*     .. Array Arguments ..
      COMPLEX*16         A( LDA, * ), AF( LDAF, * ), WORK( * ), X( * )
      DOUBLE PRECISION   RWORK( * )
*     ..
*
*  Purpose
*  =======
*
*     ZLA_PORCOND_X Computes the infinity norm condition number of
*     op(A) * diag(X) where X is a COMPLEX*16 vector.
*
*  Arguments
*  =========
*
*  C     COMPLEX*16 vector.
*
*  WORK  COMPLEX*16 workspace of size 2*N.
*
*  RWORK DOUBLE PRECISION workspace of size N.
*
*  =====================================================================
*
*     .. Local Scalars ..
      INTEGER            KASE, I, J
      DOUBLE PRECISION   AINVNM, ANORM, TMP
      LOGICAL            UP
      COMPLEX*16         ZDUM
*     ..
*     .. Local Arrays ..
      INTEGER            ISAVE( 3 )
*     ..
*     .. External Functions ..
      LOGICAL            LSAME
      EXTERNAL           LSAME
*     ..
*     .. External Subroutines ..
      EXTERNAL           ZLACN2, ZPOTRS, XERBLA
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          ABS, MAX, REAL, DIMAG
*     ..
*     .. Statement Functions ..
      DOUBLE PRECISION CABS1
*     ..
*     .. Statement Function Definitions ..
      CABS1( ZDUM ) = ABS( DBLE( ZDUM ) ) + ABS( DIMAG( ZDUM ) )
*     ..
*     .. Executable Statements ..
*
      ZLA_PORCOND_X = 0.0D+0
*
      INFO = 0
      IF( N.LT.0 ) THEN
         INFO = -2
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'ZLA_PORCOND_X', -INFO )
         RETURN
      END IF
      UP = .FALSE.
      IF ( LSAME( UPLO, 'U' ) ) UP = .TRUE.
*
*     Compute norm of op(A)*op2(C).
*
      ANORM = 0.0D+0
      IF ( UP ) THEN
         DO I = 1, N
            TMP = 0.0D+0
            DO J = 1, I
               TMP = TMP + CABS1( A( J, I ) * X( J ) )
            END DO
            DO J = I+1, N
               TMP = TMP + CABS1( A( I, J ) * X( J ) )
            END DO
            RWORK( I ) = TMP
            ANORM = MAX( ANORM, TMP )
         END DO
      ELSE
         DO I = 1, N
            TMP = 0.0D+0
            DO J = 1, I
               TMP = TMP + CABS1( A( I, J ) * X( J ) )
            END DO
            DO J = I+1, N
               TMP = TMP + CABS1( A( J, I ) * X( J ) )
            END DO
            RWORK( I ) = TMP
            ANORM = MAX( ANORM, TMP )
         END DO
      END IF
*
*     Quick return if possible.
*
      IF( N.EQ.0 ) THEN
         ZLA_PORCOND_X = 1.0D+0
         RETURN
      ELSE IF( ANORM .EQ. 0.0D+0 ) THEN
         RETURN
      END IF
*
*     Estimate the norm of inv(op(A)).
*
      AINVNM = 0.0D+0
*
      KASE = 0
   10 CONTINUE
      CALL ZLACN2( N, WORK( N+1 ), WORK, AINVNM, KASE, ISAVE )
      IF( KASE.NE.0 ) THEN
         IF( KASE.EQ.2 ) THEN
*
*           Multiply by R.
*
            DO I = 1, N
               WORK( I ) = WORK( I ) * RWORK( I )
            END DO
*
            IF ( UP ) THEN
               CALL ZPOTRS( 'U', N, 1, AF, LDAF,
     $            WORK, N, INFO )
            ELSE
               CALL ZPOTRS( 'L', N, 1, AF, LDAF,
     $            WORK, N, INFO )
            ENDIF
*
*           Multiply by inv(X).
*
            DO I = 1, N
               WORK( I ) = WORK( I ) / X( I )
            END DO
         ELSE
*
*           Multiply by inv(X').
*
            DO I = 1, N
               WORK( I ) = WORK( I ) / X( I )
            END DO
*
            IF ( UP ) THEN
               CALL ZPOTRS( 'U', N, 1, AF, LDAF,
     $            WORK, N, INFO )
            ELSE
               CALL ZPOTRS( 'L', N, 1, AF, LDAF,
     $            WORK, N, INFO )
            END IF
*
*           Multiply by R.
*
            DO I = 1, N
               WORK( I ) = WORK( I ) * RWORK( I )
            END DO
         END IF
         GO TO 10
      END IF
*
*     Compute the estimate of the reciprocal condition number.
*
      IF( AINVNM .NE. 0.0D+0 )
     $   ZLA_PORCOND_X = 1.0D+0 / AINVNM
*
      RETURN
*
      END