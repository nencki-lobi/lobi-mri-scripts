
POPULATE_INTENDED_FOR_OPTS = {
    "matching_parameters": "ModalityAcquisitionLabel",  #['ImagingVolume', 'Shims']
    "criterion": "First",
}

def create_key(template, outtype=('nii',), annotation_classes=None):
    if template is None or not template:
        raise ValueError("Template must be a valid format string")
    return (template, outtype, annotation_classes)


def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """
    t1 = create_key("{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_T1w")
    t2 = create_key("{bids_subject_session_dir}/anat/{bids_subject_session_prefix}_T2w")
    run1 = create_key("{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-stories_run-01_bold")
    run2 = create_key("{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-stories_run-02_bold")
    run3 = create_key("{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-stories_run-03_bold")
    cet = create_key("{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-cet_bold")

    fmap = create_key(
        "{bids_subject_session_dir}/fmap/{bids_subject_session_prefix}_dir-{dir}_epi"
    )

    info: dict[tuple[str, tuple[str, ...], None], list] = {
        t1: [],
        t2: [],
        run1: [],
        run2: [],
        run3: [],
        cet: [],
        fmap: [],
    }

    for idx, s in enumerate(seqinfo):
        if (s.dim3 == 208) and (s.dim4 == 1) and ("t1w" in s.protocol_name):
            info[t1] = [s.series_id]
        if (s.dim3 == 208) and ("T2w" in s.protocol_name):
            info[t2] = [s.series_id]
        
        if (s.dim4 == 1) and ("SpinEchoFieldMapAP" in s.protocol_name):
            info[fmap] = [{"item": s.series_id, "dir": "AP"}]
        if (s.dim4 == 1) and ("SpinEchoFieldMapPA" in s.protocol_name):
            info[fmap] = [{"item": s.series_id, "dir": "PA"}]

        if (s.series_files > 130) and ("task-stories r1" in s.protocol_name):
            info[run1] = [s.series_id]
        if (s.series_files > 130) and ("task-stories r2" in s.protocol_name):
            info[run2] = [s.series_id]
        if (s.series_files > 130) and ("task-stories r3" in s.protocol_name):
            info[run3] = [s.series_id]
        if (s.series_files > 300) and ("task-cet" in s.protocol_name):
            info[cet] = [s.series_id]
    return info
