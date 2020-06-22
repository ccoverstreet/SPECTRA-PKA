!begin rubric
!******************************************************************************                                                                         *
!* Original Author: Mark Gilbert                                                       *
!* mark.gilbert@ukaea.uk
!* copyright, 2015 (first version), 2018 (first git repository), UKAEA                                                     *
!******************************************************************************
!end rubric

 SUBROUTINE collapse_fluxes(fluxx,ninput_groups,noutput_groups,output_energies,input_energies)
 use globals
 IMPLICIT NONE
 ! 12/3/2018 - corrects to memory leaks due to input arrays being one less in size than groups+1
 INTEGER, INTENT (in) :: ninput_groups,noutput_groups
 REAL(KIND=DBL), INTENT (inout) :: fluxx(MAX(noutput_groups,ninput_groups))
 REAL(KIND=DBL), INTENT (in) :: output_energies(noutput_groups),input_energies(ninput_groups)
 INTEGER :: ii,jj,kk
 REAL(KIND=DBL) :: fluxx_rounded(MAX(noutput_groups,ninput_groups))
 integer :: nd1,ni
 logical :: split
 REAL (KIND=DBL) :: frac,frac2,ebottom,due,dud
 
 
!30/6/2016 modified from CEM's grpconvert routine in FISPACT-II - itself based on routines written by N.P.Taylor.

IF(do_outputs) WRITE(log_unit,*) 'collapsing fluxes'
 ! 11/7/2016 but in this routine we will always be using a grid where the value in ii corresponds to
 ! the energy bin from ii-1 to ii
 
     fluxx_rounded=0.0
     nd1=noutput_groups
     ! check for overlap of groups - shouldn't be a problem here.
     ! 11/7/2016 - in fact all the output groups with energies below the 
     ! first input group bound get a proportion of the total in the first group
     ! so we want to start from ni=1
     !ni = 0
     !do  kk = 1,nd1
     !   ni = kk
     !   if(input_energies(1).lt.output_energies(kk)) exit
     !end do
     !print *,ni

     ni = 1
 
     jj=0
     split=.false.
     outer: do kk=ni,nd1
        
        ii = kk !- 1
        
        inner: do
           if(.not.split) then
              jj = jj + 1
              if(jj>ninput_groups) exit outer
              frac = 1.0
           end if
           !IF(kk/=1) THEN
           if(input_energies(jj)>real(output_energies(ii))) exit inner
           !END IF
 
           !if(kk/=1) then
              fluxx_rounded(ii) = fluxx_rounded(ii) + fluxx(jj) * frac
           !end if
 
           split = .false.
           if(input_energies(jj) == real(output_energies(ii))) cycle outer
        end do inner
        
        IF(jj/=1) THEN
         ebottom = input_energies(jj-1)
        ELSE
         ebottom=0._DBL
        END IF
        
        if(split) THEN
         IF( ii/=1) THEN
           ebottom = output_energies(ii-1)
         ELSE
           ebottom = 0._DBL
         END IF
        END IF
        
        !lethargy method
        !due = log(ebottom/real(output_energies(ii+1)))
        !dud = log(ebottom/input_energies(jj+1))
        !flat weight method
        due = output_energies(ii)-ebottom
        dud = input_energies(jj) -ebottom      
        
        frac2 = frac * due / dud
 
        !if(kk/=1) then
           fluxx_rounded(ii) = fluxx_rounded(ii) + fluxx(jj) * frac2
        !end if
 
        frac = frac * (1.0 - due / dud)
        split = .true.
    end do outer
 
 
IF(do_outputs) WRITE(log_unit,*) "finished"
 fluxx=0._DBL
 fluxx(1:noutput_groups)=fluxx_rounded(1:noutput_groups)
IF(do_outputs) WRITE(log_unit,*) 'sent results to matrix'
 
 END SUBROUTINE collapse_fluxes
