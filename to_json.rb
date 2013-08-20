module ToJson
  include Format

  DU = Java::HarbingerSdk::DataUtils

  # requires @patientMrn to be a
  # harbinger patientMrn
  def patient_mrn_to_json(patient_mrn)
    {
      :id => d{patient_mrn.id},
      :mrn => d{patient_mrn.mrn},
      :name => Format.clean_patient_name(d{patient_mrn.patient.name}),
      :firstname => Format.firstname(d{patient_mrn.patient.name}),
      :lastname => Format.lastname(d{patient_mrn.patient.name}),
      :middle => Format.middle(d{patient_mrn.patient.name}),
      :dob => d{patient_mrn.patient.birthdate.to_s},
      :last_visit => visit_to_json(patient_mrn.visits.to_a.last),
      :exams => {
        :accessions => d{patient_mrn.radExams.collect{|e| e.accession}},
        :last => rad_exam_to_json(patient_mrn.radExams.to_a.first)
      }
    }
  end

  def visit_to_json(visit)
    {
      :id => d{visit.id},
      :number => d{visit.visit_number},
      :updated_at => d{visit.updated_at},
      :site => d{visit.site.site}
    }
  end

  #harbinger radExam
  def rad_exam_to_json(radExam)
    # all readers
    readers = [d{radExam.current_report.rad1},
      d{radExam.current_report.rad2},
      d{radExam.current_report.rad3},
      d{radExam.current_report.rad3_id},
      d{radExam.current_report.rad4}].compact
    # response
    {
      :id => d{radExam.id},
      :accession => d{radExam.accession},
      :report => d{radExam.currentReport.report_body},
      :report_event => d{radExam.currentReport.report_event.to_s},
      :modality => d{radExam.resource.modality.modality},
      :procedure => procedure_to_json(radExam.procedure),
      :reader_specialties => d{readers.collect{|r| r.specialties.to_a.collect{|s| s.specialty}}.flatten.uniq},
      :image_count => (radExam.radPacsMetadatum.image_count.to_i rescue 0),
      :readers => readers.collect{|a_reader| employee_to_json(a_reader) },
      :referring_physician => employee_to_json(radExam.radExamPersonnel.ordering),
      :status => d{radExam.currentStatus.tripStatus.status},
      :end_time => d{radExam.radExamTime.endTime.to_s},
      :begin_time => d{radExam.radExamTime.beginTime.to_s},
      :appointment => d{radExam.radExamTime.beginTime.to_s}
    }
  end

  def employee_to_json(employee)
    {
      :id => d{employee.id},
      :name => d{employee.name},
      :jhed => d{employee.identifiers.to_a.select{|i| i.external_system.external_system == "JHED"}.first.identifier},
      :specialties => d{employee.specialties.to_a.collect{|s| s.specialty}}
    }
  end

  def procedure_to_json(procedure)
    {
      :code => d{procedure.code},
      :description => d{procedure.description},
      :specialty => d{procedure.specialty_id},
      :site => d{procedure.site.site}
    }
  end
end
