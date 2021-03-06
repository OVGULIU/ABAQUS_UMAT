C
C**********************************************************************
C********************************************************************** 
C
      
      
      subroutine spectral_el(Phi1_in,PHI_in,Phi2_in,NCRYS,C11,C12,C44x2,
     # Super_set_ODF,TensorInd,index_El_r,index_El_r_aux,
     # index_El_i,index_El_i_aux,Fo_C_real,Fo_C_imag,C)
      !--------------
      !Input:
      !   Phi1,PHI,Phi2 - euler angles in degrees
      !   NCRYS - number of crystals
      !   Super_set_ODF - super set for ODF transform
      !   Fo_C - coefs for stiffness
      !   TensorInd - indices of tensor
      !Output:
      !   C - average stiffness in matrix representation
      !-----------------
      parameter SUP_IND=94,CI=(0.0,1.0),PI=3.141592653589793238462643
      integer NCRYS,b1(NCRYS),b2(NCRYS),b3(NCRYS),frequency(NCRYS),
     # TensorInd(21,4),indMap(6,2)
     # ,signInd(8,4)!test
      real*8 Phi1(NCRYS),PHI(NCRYS),Phi2(NCRYS),tempSuper(SUP_IND)
     # ,Super_set_ODF(SUP_IND,3),Ctensor(3,3,3,3),C(6,6),Id(3,3)
     # ,CtensorS(3,3,3,3),Phi1_in(NCRYS),PHI_in(NCRYS),Phi2_in(NCRYS),
     # C11,C12,C44,C44x2,temp66(6,6)
      complex FTerm(SUP_IND)!,Fo_C(21,SUP_IND)!(eff3)
      !(eff3)
      integer index_El_r(732),index_El_r_aux(22),index_El_i(711),
     # index_El_i_aux(22)
      real*8 Fo_C_real(21,SUP_IND),Fo_C_imag(21,SUP_IND)
      real*8 sum,FTerm_G(NCRYS,SUP_IND ),tempSuper_G(NCRYS,SUP_IND ),
     #Super_set_ODF_G(NCRYS,SUP_IND,3 ) 

     
      integer ii
      !----------------
      C44=C44x2*0.5
      
      !identity
      Id=0.0
      do i=1,3
          do j=1,3
              if(i.eq.j)Id(i,j)=1.0
          enddo
      enddo

      !euler angles to degrees
c      Phi1=Phi1_in*180.0/PI
c      PHI=PHI_in*180.0/PI
c      Phi2=Phi2_in*180.0/PI   
      Phi1=Phi1_in
      PHI=PHI_in
      Phi2=Phi2_in

      !to grid points
      b1=NINT(Phi1)
      b2=NINT(PHI)
      b3=NINT(Phi2)
      
      !frequencies of orientations
      call genFrequencyCount(b1,b2,b3,NCRYS,frequency) 
      
      !calculate ODF Fourier coefs
      FTerm=0.0
      FTerm_G=0.0

 
c!$omp parallel do private(tempSuper) reduction(+:FTerm)
 
      do i=1,NCRYS
          !Twiddle-Factors
          tempSuper=(Super_set_ODF(:,3)-1.0)*b1(i)+
     #     (Super_set_ODF(:,2)-1.0)*b2(i)+(Super_set_ODF(:,1)-1.0)*b3(i)
          
          !sumation of ODF Fourier coefs of single orientations
          if(frequency(i).ne.0)then
         
              FTerm=FTerm+dfloat(frequency(i))*exp(-2.0*PI*CI/360.0*
     #         tempSuper)

          endif
      enddo
 
c!$om end parallel do
  
  
#if 1 
      do ii=1,SUP_IND
      FTerm(ii)=2.0/NCRYS*FTerm(ii) !averaging, ODF Fourier coefs for polycrystal 
      Enddo    
#endif   

    
      !calculate volume average
      do i=1,21
       
        
          
          !(eff3)
c          CtensorS(TensorInd(i,1),TensorInd(i,2),TensorInd(i,3),
c     #     TensorInd(i,4))=1.0/360.0**3*
c     #     real(dot_product(Fo_C(i,:),FTerm))

          !(eff3) sum only non-zero elements, only real parts
          CtensorS(TensorInd(i,1),TensorInd(i,2),TensorInd(i,3),
     #     TensorInd(i,4))=1.0/360.0**3*(
     #     dot_product(
     #     Fo_C_real( !first term dot product
     #     i,index_El_r(index_El_r_aux(i)+1:index_El_r_aux(i+1))
     #     ), 
     #     real(FTerm( !second term dot product
     #     index_El_r(index_El_r_aux(i)+1:index_El_r_aux(i+1)))
     #     )
     #     )
     #     + dot_product(
     #     Fo_C_imag(  !first term dot product
     #     i,index_El_i(index_El_i_aux(i)+1:index_El_i_aux(i+1))
     #     ),
     #     aimag(FTerm( !second term dot product
     #     index_El_i(index_El_i_aux(i)+1:index_El_i_aux(i+1)))
     #     )
     #     )
     #     )

       
      enddo

 

      do i=1,3
          do j=i,3
              do k=1,3
                  do l=k,3
                      Ctensor(i,j,k,l)=C12*Id(i,j)*Id(k,l)
     #                +C44*(Id(i,k)*Id(j,l)+Id(i,l)*Id(j,k))+
     #                (C11-C12-2*C44)*CtensorS(i,j,k,l)
                      
                  enddo
              enddo
          enddo
      enddo
      
      !matrix representation of stiffness
      indMap(:,1)=[1,2,3,2,1,1]
      indMap(:,2)=[1,2,3,3,3,2]
      do i=1,6
          do j=i,6
              C(i,j)=Ctensor(indMap(i,1),indMap(i,2),indMap(j,1),
     #         indMap(j,2))
              C(j,i)=Ctensor(indMap(i,1),indMap(i,2),indMap(j,1),
     #         indMap(j,2))
c              write(*,*)i,j
c              write(*,*)indMap(i,1),indMap(i,2),indMap(j,1),
c     #         indMap(j,2)
c              write(*,*)'*************'
          enddo
      enddo
      
      !to abaqus notation
      temp66=C
      C(4,:)=temp66(6,:)
      C(6,:)=temp66(4,:)
      temp66=C
      C(:,4)=temp66(:,6)
      C(:,6)=temp66(:,4)

      end subroutine spectral_el
C
C**********************************************************************
C********************************************************************** 
C
      subroutine genFrequencyCount(b1,b2,b3,NCRYS,frequency)
      integer NCRYS,b1(NCRYS),b2(NCRYS),b3(NCRYS),frequency(NCRYS)
      
      frequency=1
c#ifdef UGPU
c!$ACC kernels
c!$ACC loop independent
c!$ACC& Private(i,j,frequency)
c#endif      
      do i=1,NCRYS
          do j=i+1,NCRYS
              if(b1(i).eq.b1(j).and.b2(i).eq.b2(j)
     #         .and.b3(i).eq.b3(j))then
                  frequency(i)=frequency(i)+1
                  frequency(j)=0
              endif
          enddo
      enddo
c#ifdef UGPU
c!$ACC end kernels
c#endif
      end subroutine genFrequencyCount
C
C**********************************************************************
C********************************************************************** 
C
      
!*******************************************
!*******************************************      
      
      		SUBROUTINE euler2Q (NCRYS, Phi1, PHI, Phi2, Q_c_s)

!		Input: Euler angles in degrees.
!		Output: 3d array of transformation matrices crystal to sample
		REAL*8 PI
		INTEGER i,NCRYS
		PARAMETER (PI = 3.1415926535897932384626433832795)
		REAL*8 Phi1(NCRYS), PHI(NCRYS), Phi2(NCRYS), Q_c_s(NCRYS,3,3)  
		REAL*8 SPhi1(NCRYS), CPhi1(NCRYS), SPHI(NCRYS), CPHI(NCRYS)      
		REAL*8 SPhi2(NCRYS), CPhi2(NCRYS), to_rad, to_deg

          to_rad = PI / 180.d0!here was error
		to_deg = 1.d0 / to_rad
    
		Phi1 = to_rad * Phi1 
		PHI  = to_rad * PHI
		Phi2 = to_rad * Phi2

		SPhi1 = DSIN(Phi1)
		CPhi1 = DCOS(Phi1)
		SPHI  = DSIN(PHI)
		CPHI  = DCOS(PHI)
		SPhi2 = DSIN(Phi2)
		CPhi2 = DCOS(Phi2)
    
		DO i = 1,NCRYS
        
			Q_c_s(i,1,1) = CPhi1(i)*CPhi2(i)-SPhi1(i)*CPHI(i)*SPhi2(i)
			Q_c_s(i,1,2) = -CPhi1(i)*SPhi2(i)-SPhi1(i)*CPHI(i)*CPhi2(i)
			Q_c_s(i,1,3) = SPhi1(i)*SPHI(i) 
			Q_c_s(i,2,1) = SPhi1(i)*CPhi2(i)+CPhi1(i)*CPHI(i)*SPhi2(i)
			Q_c_s(i,2,2) = -SPhi1(i)*SPhi2(i)+CPhi1(i)*CPHI(i)*CPhi2(i)
			Q_c_s(i,2,3) = -CPhi1(i)*SPHI(i)
			Q_c_s(i,3,1) = SPHI(i)*SPhi2(i)
			Q_c_s(i,3,2) = SPHI(i)*CPhi2(i)
			Q_c_s(i,3,3) = CPHI(i)
    
		ENDDO
    
			Phi1 = to_deg * Phi1 
			PHI  = to_deg * PHI
			Phi2 = to_deg * Phi2

		RETURN
    
		END SUBROUTINE euler2Q



    
      SUBROUTINE ELAST_BCC(Q, C11, C12, C44, ELAS)
	  implicit none
C
C      INCLUDE 'C:\Milan\PhD\Research\1000_model\COMM.f'

        REAL*8 C11, C12, C44, Q(3,3), ELAS(6,6), HC44, HALF


C      INTEGER INTP
C      
      HALF = 0.5D0      
      HC44 = HALF*C44 ! IN INPUT FILE C44 = 2*C44
C
C
      ELAS(1,1) = C12 + C44 + (C11 - C12 - C44)*
     &   (Q(1,1)*Q(1,1)*Q(1,1)*Q(1,1) + Q(1,2)*Q(1,2)*Q(1,2)*Q(1,2) +
     &    Q(1,3)*Q(1,3)*Q(1,3)*Q(1,3))
C
C
      ELAS(2,2) = C12 + C44 + (C11 - C12 - C44)*
     &  (Q(2,1)*Q(2,1)*Q(2,1)*Q(2,1) + Q(2,2)*Q(2,2)*Q(2,2)*Q(2,2) +
     &  Q(2,3)*Q(2,3)*Q(2,3)*Q(2,3))
C
C
      ELAS(3,3) = C12 + C44 + (C11 - C12 - C44)* 
     &  (Q(3,1)*Q(3,1)*Q(3,1)*Q(3,1) + Q(3,2)*Q(3,2)*Q(3,2)*Q(3,2) +
     &   Q(3,3)*Q(3,3)*Q(3,3)*Q(3,3))
C
C
      ELAS(1,2) = C12 + (C11 - C12 - C44)* 
     & (Q(1,1)*Q(1,1)*Q(2,1)*Q(2,1) + Q(1,2)*Q(1,2)*Q(2,2)*Q(2,2) + 
     &  Q(1,3)*Q(1,3)*Q(2,3)*Q(2,3))
C
C
      ELAS(1,3) = C12 + (C11 - C12 - C44)*
     & (Q(1,1)*Q(1,1)*Q(3,1)*Q(3,1) + Q(1,2)*Q(1,2)*Q(3,2)*Q(3,2) + 
     &  Q(1,3)*Q(1,3)*Q(3,3)*Q(3,3))
C
C
      ELAS(2,3) = C12 + (C11 - C12 - C44)* 
     & (Q(2,1)*Q(2,1)*Q(3,1)*Q(3,1) + Q(2,2)*Q(2,2)*Q(3,2)*Q(3,2) + 
     &  Q(2,3)*Q(2,3)*Q(3,3)*Q(3,3))
C
C
C
        ELAS(2,1) = ELAS(1,2)
        ELAS(3,1) = ELAS(1,3)
        ELAS(3,2) = ELAS(2,3)
C
C
      ELAS(4,4) = HC44 + (C11 - C12 - C44)* 
     & (Q(1,1)*Q(2,1)*Q(1,1)*Q(2,1) + Q(1,2)*Q(2,2)*Q(1,2)*Q(2,2) + 
     &  Q(1,3)*Q(2,3)*Q(1,3)*Q(2,3))
C
C
      ELAS(5,5) = HC44 + (C11 - C12 - C44)* 
     & (Q(1,1)*Q(3,1)*Q(1,1)*Q(3,1) + Q(1,2)*Q(3,2)*Q(1,2)*Q(3,2) + 
     &  Q(1,3)*Q(3,3)*Q(1,3)*Q(3,3))
C
C
      ELAS(6,6) = HC44 + (C11 - C12 - C44)* 
     & (Q(2,1)*Q(3,1)*Q(2,1)*Q(3,1) + Q(2,2)*Q(3,2)*Q(2,2)*Q(3,2) + 
     &  Q(2,3)*Q(3,3)*Q(2,3)*Q(3,3))
C
C
      ELAS(4,5) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(2,1)*Q(1,1)*Q(3,1) + Q(1,2)*Q(2,2)*Q(1,2)*Q(3,2) + 
     &  Q(1,3)*Q(2,3)*Q(1,3)*Q(3,3))   
C
C
      ELAS(4,6) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(2,1)*Q(2,1)*Q(3,1) + Q(1,2)*Q(2,2)*Q(2,2)*Q(3,2) + 
     &  Q(1,3)*Q(2,3)*Q(2,3)*Q(3,3))  
C
C
      ELAS(5,6) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(3,1)*Q(2,1)*Q(3,1) + Q(1,2)*Q(3,2)*Q(2,2)*Q(3,2) + 
     &  Q(1,3)*Q(3,3)*Q(2,3)*Q(3,3))
C
C
C
        ELAS(5,4) = ELAS(4,5)
        ELAS(6,4) = ELAS(4,6)
        ELAS(6,5) = ELAS(5,6)!correction
C
C
      ELAS(1,4) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(1,1)*Q(1,1)*Q(2,1) + Q(1,2)*Q(1,2)*Q(1,2)*Q(2,2) + 
     &  Q(1,3)*Q(1,3)*Q(1,3)*Q(2,3))
C
C
      ELAS(1,5) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(1,1)*Q(1,1)*Q(3,1) + Q(1,2)*Q(1,2)*Q(1,2)*Q(3,2) + 
     &  Q(1,3)*Q(1,3)*Q(1,3)*Q(3,3))
C
C
      ELAS(1,6) = (C11 - C12 - C44)* 
     & (Q(1,1)*Q(1,1)*Q(2,1)*Q(3,1) + Q(1,2)*Q(1,2)*Q(2,2)*Q(3,2) + 
     &  Q(1,3)*Q(1,3)*Q(2,3)*Q(3,3))
C
C
      ELAS(2,4) = (C11 - C12 - C44)* 
     & (Q(2,1)*Q(2,1)*Q(1,1)*Q(2,1) + Q(2,2)*Q(2,2)*Q(1,2)*Q(2,2) + 
     &  Q(2,3)*Q(2,3)*Q(1,3)*Q(2,3))
C
C
      ELAS(2,5) = (C11 - C12 - C44)* 
     & (Q(2,1)*Q(2,1)*Q(1,1)*Q(3,1) + Q(2,2)*Q(2,2)*Q(1,2)*Q(3,2) +  
     &  Q(2,3)*Q(2,3)*Q(1,3)*Q(3,3))
C
C
      ELAS(2,6) = (C11 - C12 - C44)* 
     & (Q(2,1)*Q(2,1)*Q(2,1)*Q(3,1) + Q(2,2)*Q(2,2)*Q(2,2)*Q(3,2) + 
     &  Q(2,3)*Q(2,3)*Q(2,3)*Q(3,3))
C
C
      ELAS(3,4) = (C11 - C12 - C44)* 
     & (Q(3,1)*Q(3,1)*Q(1,1)*Q(2,1) + Q(3,2)*Q(3,2)*Q(1,2)*Q(2,2) + 
     &  Q(3,3)*Q(3,3)*Q(1,3)*Q(2,3))
C
C
      ELAS(3,5) = (C11 - C12 - C44)* 
     & (Q(3,1)*Q(3,1)*Q(1,1)*Q(3,1) + Q(3,2)*Q(3,2)*Q(1,2)*Q(3,2) + 
     &  Q(3,3)*Q(3,3)*Q(1,3)*Q(3,3))
C
C
      ELAS(3,6) = (C11 - C12 - C44)* 
     & (Q(3,1)*Q(3,1)*Q(2,1)*Q(3,1) + Q(3,2)*Q(3,2)*Q(2,2)*Q(3,2) + 
     &  Q(3,3)*Q(3,3)*Q(2,3)*Q(3,3))
C
C
C        
         ELAS(4,1) = ELAS(1,4)
         ELAS(4,2) = ELAS(2,4)
         ELAS(4,3) = ELAS(3,4)
         ELAS(5,1) = ELAS(1,5)
         ELAS(5,2) = ELAS(2,5)
         ELAS(5,3) = ELAS(3,5)
         ELAS(6,1) = ELAS(1,6)
         ELAS(6,2) = ELAS(2,6)
         ELAS(6,3) = ELAS(3,6)        
C      
C      DO K1 = 1,6
C       DO K2 = 1,6
C        IF (K2.GT.3) THEN
C         ELAS(K1,K2) = ELAS(K1,K2,ICRYS,KINTK)*2.0D0 ! comment: what is KINTK?
C        ENDIF
C       ENDDO
C      ENDDO
C        
      RETURN
      END SUBROUTINE ELAST_BCC
c#####################################################      
c#####################################################
      
       subroutine euler(iopt,ph,th,tm,a)
      dimension a(3,3)
      pi=4.*atan(1.d0)
c
c     CALCULATE THE EULER ANGLES ASSOCIATED WITH THE TRANSFORMATION
c     MATRIX A(I,J) IF IOPT=1 AND VICEVERSA IF IOPT=2
c     A(i,j) TRANSFORMS FROM SYSTEM sa TO SYSTEM ca.
c     ph,th,om ARE THE EULER ANGLES OF ca REFERRED TO sa.
c
      if(iopt.eq.1) then
        th=acos(a(3,3))
        if(abs(a(3,3)).ge.0.9999) then
          tm=0.
          ph=atan2(a(1,2),a(1,1))
        else
          sth=sin(th)
          tm=atan2(a(1,3)/sth,a(2,3)/sth)
          ph=atan2(a(3,1)/sth,-a(3,2)/sth)
        endif
        th=th*180./pi
        ph=ph*180./pi
        tm=tm*180./pi
         
      else if(iopt.eq.2) then
        sph=sin(ph)
        cph=cos(ph)
        sth=sin(th)
        cth=cos(th)
        stm=sin(tm)
        ctm=cos(tm)
        a(1,1)=ctm*cph-sph*stm*cth
        a(2,1)=-stm*cph-sph*ctm*cth
        a(3,1)=sph*sth
        a(1,2)=ctm*sph+cph*stm*cth
        a(2,2)=-sph*stm+cph*ctm*cth
        a(3,2)=-sth*cph
        a(1,3)=sth*stm
        a(2,3)=ctm*sth
        a(3,3)=cth
      endif

      return
      end
c
      
      
c#####################################################      
c#####################################################     
      
      
      
      
      
      subroutine orient(a,c)
      dimension a(3,3),c(3,3),th2(3,3),v(3),vbar(3)
      dimension th(3,3)
      dimension rot(3,3),anew(3,3)

c     BUILD ROTATION TENSOR BASED ON RODRIGUES FORMULA

c#if 0
c      v(1)=c(3,2)
c      v(2)=c(1,3)
c      v(3)=c(2,1)
cc      v(4)=c(1,1)
cc      v(5)=c(2,2)
cc      v(6)=c(3,3)
      
c      snorm=sqrt(v(1)*v(1)+v(2)*v(2)+v(3)*v(3) 
cc     #      +v(4)*v(4)+v(5)*v(5)+v(6)*v(6) )
c      snorm1=tan(snorm/2.)
c      if(snorm.gt.1.e-06) go to 97
c      snorm=1.
c97    do 20 i=1,3
c      vbar(i)=snorm1*v(i)/snorm
c20    continue
c      snorm=vbar(1)*vbar(1)+vbar(2)*vbar(2)+vbar(3)*vbar(3)
cc     # +vbar(4)*vbar(4)+vbar(5)*vbar(5)+vbar(6)*vbar(6)
c      th(3,2)=vbar(1)
c      th(1,3)=vbar(2)
c      th(2,1)=vbar(3)
c      th(2,3)=-vbar(1)
c      th(3,1)=-vbar(2)
c      th(1,2)=-vbar(3)
c      do 40 i=1,3
c40    th(i,i)=0.
c      do 30 i=1,3
c      do 30 j=1,3
c      th2(i,j)=0.
c      do 50 k=1,3
c50    th2(i,j)=th2(i,j)+th(i,k)*th(k,j)
c30    continue
c      do 60 i=1,3
c      do 60 j=1,3
c60    rot(i,j)=(i/j)*(j/i)+2.*(th(i,j)+th2(i,j))/(1.+snorm)
      
c#endif     
      do 70 i=1,3
      do 70 j=1,3
      anew(i,j)=0.
      do 80 k=1,3
80    anew(i,j)=anew(i,j)+c(i,k)*a(k,j)
70    continue
      do 90 i=1,3
      do 90 j=1,3
90    a(i,j)=anew(i,j)
      f=2
      return
      end
c
C *****************************************************************************       
  
    
